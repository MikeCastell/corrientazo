import React, { useState, useEffect } from 'react';
import { db } from './firebase';
import { 
  collection, 
  onSnapshot, 
  addDoc, 
  updateDoc, 
  doc, 
  query, 
  where, 
  orderBy, 
  serverTimestamp,
  runTransaction
} from 'firebase/firestore';
import { Home as HomeIcon, ChefHat, ShoppingBag, MapPin, Clock, ChevronLeft, Plus, CheckCircle, Package, Loader2 } from 'lucide-react';

export default function App() {
  const [view, setView] = useState('home'); // home, detail, order, confirmation, cookProfile, createProduct
  const [loading, setLoading] = useState(true);
  const [createSuccess, setCreateSuccess] = useState(false);
  
  const [products, setProducts] = useState([]);
  const [orders, setOrders] = useState([]);
  
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [orderType, setOrderType] = useState('pickup'); // pickup, delivery
  const [customerName, setCustomerName] = useState(localStorage.getItem('clienteNombre') || '');
  
  // Perfil hardcodeado por ahora (como pidió el usuario, para que funcione de inmediato)
  const [currentUser] = useState({
    id: 'cocinero_pro_1',
    nombre: 'Doña Marta',
    tipo: 'cocinero',
    ubicacion: 'Calle 45 #12-34'
  });

  // 1. Escuchar platos (meals) en tiempo real
  useEffect(() => {
    const q = query(collection(db, 'meals'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const mealsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setProducts(mealsData);
      setLoading(false);
    }, (error) => {
      console.error("Error al cargar platos:", error);
      alert("Error al cargar los datos. Revisa la configuración de Firebase.");
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // 2. Escuchar pedidos (orders) en tiempo real (si es cocinero, solo los suyos)
  useEffect(() => {
    const q = query(collection(db, 'orders'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const ordersData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setOrders(ordersData);
    });

    return () => unsubscribe();
  }, []);

  // Navegación
  const navigate = (viewName, product = null) => {
    if (product) setSelectedProduct(product);
    if (viewName === 'createProduct') setCreateSuccess(false);
    setView(viewName);
    window.scrollTo(0, 0);
  };

  // --- ACCIONES ---

  const handleCreateMeal = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const formData = new FormData(e.target);
      
      // Capturar valores del formulario
      const nombre = formData.get('name') || "";
      const descripcion = formData.get('description') || "";
      const precio = parseInt(formData.get('priceDelivery')) || 0;
      const precioRecogida = parseInt(formData.get('pricePickup')) || 0;
      const cantidadDisponible = parseInt(formData.get('available')) || 0;
      const tiempoEstimado = formData.get('estimatedTime') || "20 min";
      const imagen = 'https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&q=80&w=600';

      // Datos del cocinero (saneados)
      const nombreCocinero = currentUser.nombre || "Cocinero";
      const cocineroId = currentUser.id || "anon";
      const ubicacion = currentUser.ubicacion || "Local";

      console.log("Intentando guardar...");
      
      const mealData = {
        nombre,
        descripcion,
        precio,
        precioRecogida,
        cantidadDisponible,
        cocineroId,
        nombreCocinero,
        ubicacion,
        tiempoEstimado,
        imagen,
        createdAt: new Date()
      };


      // Timeout de seguridad para detectar si Firebase se queda "colgado" (esperando red o config)
      const timeout = setTimeout(() => {
        alert("⏳ El guardado está tardando demasiado. Esto suele pasar si:\n1. No has activado Firestore en la consola de Firebase.\n2. Las reglas de seguridad bloquean la escritura.\n3. Tu conexión a internet es inestable.");
      }, 10000);

      await addDoc(collection(db, "meals"), mealData);
      
      clearTimeout(timeout);
      console.log("Guardado exitoso");
      
      setCreateSuccess(true);
      setTimeout(() => {
        setCreateSuccess(false);
        navigate('cookProfile');
      }, 3000);

    } catch (error) {
      console.error("Error al guardar:", error);
      alert(`❌ Error al publicar: ${error.message || "Intenta nuevamente"}`);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateOrder = async () => {
    if (!selectedProduct) return;
    if (!customerName.trim()) {
      alert("Por favor ingresa tu nombre para el pedido.");
      return;
    }
    
    setLoading(true);
    localStorage.setItem('clienteNombre', customerName);

    try {
      const mealRef = doc(db, 'meals', selectedProduct.id);
      
      await runTransaction(db, async (transaction) => {
        const mealDoc = await transaction.get(mealRef);
        if (!mealDoc.exists()) throw "El plato ya no existe en el menú.";

        const mealData = mealDoc.data();
        const currentAvailable = mealData.cantidadDisponible || 0;
        
        if (currentAvailable <= 0) throw "¡Lo sentimos! Este plato se acaba de agotar.";

        // 1. Reducir cantidad
        transaction.update(mealRef, {
          cantidadDisponible: currentAvailable - 1
        });

        // 2. Crear pedido con datos saneados (sin undefined)
        const finalPrice = orderType === 'pickup' ? (selectedProduct.precioRecogida || 0) : (selectedProduct.precio || 0);
        
        const newOrder = {
          mealId: selectedProduct.id,
          nombrePlato: selectedProduct.nombre || "Plato sin nombre",
          clienteNombre: customerName.trim(),
          tipoEntrega: orderType,
          metodoPago: "manual",
          estado: 'pendiente',
          precio: finalPrice,
          cocineroId: selectedProduct.cocineroId || "desconocido",
          nombreCocinero: selectedProduct.nombreCocinero || "Cocinero",
          createdAt: serverTimestamp()
        };

        const orderRef = doc(collection(db, 'orders'));
        transaction.set(orderRef, newOrder);
      });

      navigate('confirmation', selectedProduct);
    } catch (error) {
      console.error("Error en el pedido:", error);
      alert(typeof error === 'string' ? error : "Hubo un problema al procesar tu pedido. Intenta de nuevo.");
    } finally {
      setLoading(false);
    }
  };

  const updateOrderStatus = async (orderId, newStatus) => {
    try {
      const orderRef = doc(db, 'orders', orderId);
      await updateDoc(orderRef, { estado: newStatus });
    } catch (error) {
      console.error("Error al actualizar pedido:", error);
      alert("No se pudo actualizar el estado.");
    }
  };

  // --- VIEWS ---

  const renderHome = () => {
    // Mostrar todos los platos, pero marcar los que no tienen stock
    const allProducts = products;

    return (
      <div className="animate-fade-in">
        <div className="app-header">
          <div>
            <h1 className="text-xl text-primary flex items-center gap-2">
              <ChefHat /> CORRIENTAZO
            </h1>
            <p className="text-xs flex items-center gap-1 mt-1"><MapPin size={12}/> Disponibles ahora</p>
          </div>
          <button onClick={() => navigate('cookProfile')} className="p-2 rounded-full bg-orange-100 text-primary">
            <ChefHat size={20} />
          </button>
        </div>

        <div className="p-4 flex flex-col gap-4 pb-24">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-20 gap-4">
              <Loader2 className="animate-spin text-primary" size={40} />
              <p className="text-gray-500">Cargando platos desde Firestore...</p>
            </div>
          ) : allProducts.length === 0 ? (
            <div className="text-center py-10">
              <Package size={48} className="mx-auto text-gray-300 mb-4" />
              <p className="text-gray-500">No hay platos publicados todavía.</p>
              <button onClick={() => navigate('cookProfile')} className="btn-primary mt-4 w-auto px-6">Publicar el primero</button>
            </div>
          ) : (
            allProducts.map(product => {
              const isSoldOut = product.cantidadDisponible <= 0;
              const savings = product.precio - product.precioRecogida;
              return (
                <div key={product.id} className="bg-card-bg rounded-lg shadow-sm overflow-hidden" style={{ opacity: isSoldOut ? 0.6 : 1 }}>
                  <div className="relative h-48">
                    <img src={product.imagen} alt={product.nombre} className="w-full h-full object-cover" />
                    <div className="absolute top-2 left-2 bg-white/90 px-2 py-1 rounded-md text-xs font-bold flex items-center gap-1 backdrop-blur-sm">
                      <Clock size={12} className="text-primary"/> {product.tiempoEstimado}
                    </div>
                    {!isSoldOut ? (
                      <div className="absolute top-2 right-2 bg-white/90 px-2 py-1 rounded-md text-xs font-bold backdrop-blur-sm">
                        Quedan {product.cantidadDisponible}
                      </div>
                    ) : (
                      <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                        <span className="bg-red-500 text-white px-4 py-2 rounded-lg font-bold text-lg">AGOTADO</span>
                      </div>
                    )}
                  </div>
                  
                  <div className="p-4">
                    <div className="flex justify-between items-start mb-2">
                      <h3 className="text-lg leading-tight">{product.nombre}</h3>
                      <p className="font-bold text-lg">${product.precioRecogida.toLocaleString()}</p>
                    </div>
                    <p className="text-sm mb-3 font-medium flex items-center gap-1">👨‍🍳 {product.nombreCocinero}</p>
                    <div className="flex justify-between items-center mb-4">
                      <p className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-md inline-block font-medium">
                        Ahorras ${savings.toLocaleString()} si recoges
                      </p>
                    </div>
                    <button 
                      onClick={() => navigate('detail', product)} 
                      disabled={isSoldOut}
                      className="btn-primary w-full"
                      style={{ backgroundColor: isSoldOut ? '#cbd5e1' : 'var(--primary-color)' }}
                    >
                      {isSoldOut ? 'No disponible' : 'Ver plato'}
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    );
  };

  const renderDetail = () => {
    if (!selectedProduct) return null;
    const p = selectedProduct;
    const savings = p.precio - p.precioRecogida;

    return (
      <div className="animate-fade-in bg-white min-h-screen">
        <div className="relative h-64">
          <button onClick={() => navigate('home')} className="absolute top-4 left-4 z-10 bg-white/80 p-2 rounded-full shadow-md backdrop-blur-md">
            <ChevronLeft size={24} />
          </button>
          <img src={p.imagen} alt={p.nombre} className="w-full h-full object-cover" />
        </div>

        <div className="p-4">
          <h2 className="text-2xl mb-2">{p.nombre}</h2>
          <p className="text-sm font-medium mb-4 flex items-center gap-1 border-b border-gray-100 pb-4">
            👨‍🍳 {p.nombreCocinero} <span className="text-gray-300 mx-2">•</span> <MapPin size={14}/> {p.ubicacion}
          </p>
          <p className="text-gray-600 mb-6 leading-relaxed">{p.descripcion}</p>

          <div className="bg-gray-50 p-4 rounded-xl mb-6">
            <h3 className="font-bold mb-3 flex items-center gap-2"><Clock size={16} className="text-primary"/> {p.tiempoEstimado}</h3>
            <div className="flex justify-between items-center mb-2">
              <span className="text-gray-600">Precio Domicilio</span>
              <span className="font-bold">${p.precio.toLocaleString()}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-gray-600">Precio Recogida</span>
              <span className="font-bold text-action text-lg">${p.precioRecogida.toLocaleString()}</span>
            </div>
            <div className="mt-2 text-right">
               <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-md font-medium">Ahorras ${savings.toLocaleString()}</span>
            </div>
          </div>

          <div className="flex gap-3 mt-8">
            <button onClick={() => { setOrderType('pickup'); navigate('order', p); }} className="flex-1 bg-white border-2 border-action text-action py-3 rounded-xl font-bold flex flex-col items-center justify-center">
              <Package size={20} className="mb-1" /> Recoger
            </button>
            <button onClick={() => { setOrderType('delivery'); navigate('order', p); }} className="flex-1 bg-action text-white py-3 rounded-xl font-bold flex flex-col items-center justify-center shadow-md shadow-green-200">
              <MapPin size={20} className="mb-1" /> Domicilio
            </button>
          </div>
        </div>
      </div>
    );
  };

  const renderOrder = () => {
    if (!selectedProduct) return null;
    const p = selectedProduct;
    const finalPrice = orderType === 'pickup' ? p.precioRecogida : p.precio;

    return (
      <div className="animate-fade-in bg-gray-50 min-h-screen">
        <div className="app-header">
          <button onClick={() => navigate('detail', p)}><ChevronLeft size={24} /></button>
          <h2 className="text-lg font-bold">Resumen</h2>
          <div className="w-6"></div>
        </div>

        <div className="p-4">
          <div className="bg-white p-4 rounded-xl shadow-sm mb-4 flex gap-4">
            <img src={p.imagen} className="w-20 h-20 rounded-lg object-cover" alt={p.nombre} />
            <div>
              <h3 className="font-bold">{p.nombre}</h3>
              <p className="text-sm text-gray-500">{orderType === 'pickup' ? 'Para recoger' : 'A domicilio'}</p>
              <p className="font-bold text-primary mt-1">${finalPrice.toLocaleString()}</p>
            </div>
          </div>

          <div className="bg-white p-4 rounded-xl shadow-sm mb-4">
            <h3 className="font-bold mb-3">Tus datos</h3>
            <input 
              type="text" 
              placeholder="Tu nombre completo" 
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              className="mb-1"
              required
            />
            <p className="text-xs text-gray-400">Para que el cocinero sepa quién eres.</p>
          </div>

          <div className="bg-white p-4 rounded-xl shadow-sm mb-6">
            <h3 className="font-bold mb-3">Método de pago</h3>
            <div className="flex flex-col gap-3">
              <label className="flex items-center gap-3 p-3 border rounded-lg cursor-pointer">
                <input type="radio" name="payment" defaultChecked className="w-4 h-4 text-primary" />
                <div>
                  <p className="font-bold">Pago Manual</p>
                  <p className="text-xs text-gray-500">Pagas en efectivo o transferencia directa.</p>
                </div>
              </label>
            </div>
          </div>

          <button onClick={handleCreateOrder} disabled={loading} className="btn-action shadow-lg shadow-green-200">
            {loading ? <Loader2 className="animate-spin" /> : `Confirmar pedido • $${finalPrice.toLocaleString()}`}
          </button>
        </div>
      </div>
    );
  };

  const renderConfirmation = () => (
    <div className="animate-fade-in bg-white min-h-screen flex flex-col items-center justify-center p-6 text-center">
      <CheckCircle size={80} className="text-action mb-6" />
      <h2 className="text-2xl font-bold mb-2">¡Pedido enviado!</h2>
      <p className="text-gray-600 mb-8">En breve el cocinero aceptará tu pedido.</p>
      <button onClick={() => navigate('home')} className="btn-primary">Volver al inicio</button>
    </div>
  );

  const renderCookProfile = () => {
    // Filtrar pedidos para este cocinero
    const cookOrders = orders.filter(o => o.cocineroId === currentUser.id);

    return (
      <div className="animate-fade-in bg-gray-50 min-h-screen pb-24">
        <div className="app-header">
          <button onClick={() => navigate('home')}><ChevronLeft size={24} /></button>
          <h2 className="text-lg font-bold">Panel Cocinero</h2>
          <div className="w-6"></div>
        </div>

        <div className="p-4">
          <div className="bg-white p-6 rounded-xl shadow-sm text-center mb-6">
            <div className="w-20 h-20 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-3">
              <ChefHat size={32} className="text-primary" />
            </div>
            <h2 className="text-xl font-bold">{currentUser.nombre}</h2>
            <p className="text-sm text-gray-500">{currentUser.ubicacion}</p>
          </div>

          <h3 className="font-bold text-lg mb-4">Pedidos Recibidos</h3>
          <div className="flex flex-col gap-3 mb-8">
            {cookOrders.length === 0 ? (
               <p className="text-gray-500 text-center py-10 bg-white rounded-xl">No hay pedidos aún.</p>
            ) : (
              cookOrders.map(order => (
                <div key={order.id} className={`bg-white p-4 rounded-xl shadow-sm border-l-4 ${order.estado === 'entregado' ? 'border-gray-300' : 'border-action'}`}>
                  <div className="flex justify-between items-start mb-2">
                    <h4 className="font-bold">{order.nombrePlato}</h4>
                    <span className="text-sm font-bold">${order.precio.toLocaleString()}</span>
                  </div>
                  <p className="text-xs text-gray-500 mb-3">{order.tipoEntrega === 'pickup' ? 'Recoger' : 'Domicilio'} • <span className="uppercase font-bold text-primary">{order.estado}</span></p>
                  
                  {order.estado !== 'entregado' && (
                    <div className="flex gap-2">
                      {order.estado === 'pendiente' && (
                        <button onClick={() => updateOrderStatus(order.id, 'aceptado')} className="flex-1 bg-blue-500 text-white py-2 rounded-lg text-xs font-bold">Aceptar</button>
                      )}
                      {order.estado === 'aceptado' && (
                        <button onClick={() => updateOrderStatus(order.id, 'preparando')} className="flex-1 bg-orange-500 text-white py-2 rounded-lg text-xs font-bold">Preparar</button>
                      )}
                      {order.estado === 'preparando' && (
                        <button onClick={() => updateOrderStatus(order.id, 'entregado')} className="flex-1 bg-action text-white py-2 rounded-lg text-xs font-bold">Entregar</button>
                      )}
                    </div>
                  )}
                </div>
              ))
            )}
          </div>

          <button onClick={() => navigate('createProduct')} className="btn-primary flex justify-center items-center gap-2 shadow-lg shadow-orange-200">
            <Plus size={20} /> Publicar Nuevo Plato
          </button>
        </div>
      </div>
    );
  };

  const renderCreateProduct = () => {
    if (createSuccess) {
      return (
        <div className="animate-fade-in bg-white min-h-screen flex flex-col items-center justify-center p-6 text-center">
          <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mb-6">
            <CheckCircle size={40} className="text-action" />
          </div>
          <h2 className="text-2xl font-bold mb-2">✅ Plato publicado correctamente</h2>
          <p className="text-gray-500 mb-8">Tus clientes ya pueden verlo en el menú.</p>
          
          <div className="flex flex-col gap-3 w-full">
            <button 
              onClick={() => { setCreateSuccess(false); navigate('cookProfile'); }} 
              className="btn-primary"
            >
              Ver mis platos
            </button>
            <button 
              onClick={() => { setCreateSuccess(false); setView('createProduct'); }} 
              className="btn-outline"
            >
              Crear otro
            </button>
          </div>
          <p className="text-xs text-gray-400 mt-8">Redirigiendo a Mi Cocina...</p>
        </div>
      );
    }

    return (
      <div className="animate-fade-in bg-white min-h-screen">
        <div className="app-header shadow-none border-b border-gray-100">
          <button onClick={() => navigate('cookProfile')}><ChevronLeft size={24} /></button>
          <h2 className="text-lg font-bold">Nuevo Corrientazo</h2>
          <div className="w-6"></div>
        </div>

        <form onSubmit={handleCreateMeal} className="p-4 flex flex-col gap-4">
          <div className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center text-gray-500 mb-2 bg-gray-50">
             <ChefHat size={32} className="mx-auto mb-2 opacity-50" />
             <p className="text-sm">Foto del plato (Placeholder)</p>
          </div>

          <div>
            <label className="block text-sm font-bold mb-1">Nombre del plato</label>
            <input type="text" name="name" required placeholder="Ej: Sancocho" />
          </div>

          <div className="flex gap-4">
            <div className="flex-1">
              <label className="block text-sm font-bold mb-1">Precio Domicilio</label>
              <input type="number" name="priceDelivery" required placeholder="$" />
            </div>
            <div className="flex-1">
              <label className="block text-sm font-bold mb-1 text-action">Precio Recogida</label>
              <input type="number" name="pricePickup" required placeholder="$" />
            </div>
          </div>

          <div className="flex gap-4">
            <div className="flex-1">
              <label className="block text-sm font-bold mb-1">Cantidad Inicial</label>
              <input type="number" name="available" required placeholder="5" />
            </div>
            <div className="flex-1">
              <label className="block text-sm font-bold mb-1">Tiempo</label>
              <input type="text" name="estimatedTime" required placeholder="20 min" />
            </div>
          </div>

          <div>
            <label className="block text-sm font-bold mb-1">Descripción</label>
            <textarea name="description" rows="3" required placeholder="Ingredientes..."></textarea>
          </div>

          <button type="submit" disabled={loading} className="btn-primary mt-4 shadow-lg shadow-orange-200">
            {loading ? <Loader2 className="animate-spin" /> : "Publicar Ahora"}
          </button>
        </form>
      </div>
    );
  };

  return (
    <>
      <div className="main-content">
        {view === 'home' && renderHome()}
        {view === 'detail' && renderDetail()}
        {view === 'order' && renderOrder()}
        {view === 'confirmation' && renderConfirmation()}
        {view === 'cookProfile' && renderCookProfile()}
        {view === 'createProduct' && renderCreateProduct()}
      </div>

      {(view === 'home' || view === 'cookProfile') && (
        <nav className="bottom-nav">
          <button className={`nav-item ${view === 'home' ? 'active' : ''}`} onClick={() => navigate('home')}>
            <HomeIcon size={24} /> <span>Explorar</span>
          </button>
          <button className="nav-item">
            <ShoppingBag size={24} /> <span>Mis Compras</span>
          </button>
          <button className={`nav-item ${view === 'cookProfile' ? 'active' : ''}`} onClick={() => navigate('cookProfile')}>
            <ChefHat size={24} /> <span>Mi Cocina</span>
          </button>
        </nav>
      )}
    </>
  );
}
