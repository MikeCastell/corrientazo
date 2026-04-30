import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

// CONFIGURACIÓN DE FIREBASE (EXTRAÍDA AUTOMÁTICAMENTE)
const firebaseConfig = {
  apiKey: "AIzaSyCr9Y2OUa9FbpUUmQIAk1WcLqkx2ptgAys",
  authDomain: "corrientazo-app.firebaseapp.com",
  projectId: "corrientazo-app",
  storageBucket: "corrientazo-app.firebasestorage.app",
  messagingSenderId: "734250904900",
  appId: "1:734250904900:web:7c2f9d388b303de53dfb11",
  measurementId: "G-3DQ6266H4F"
};

// Inicializar Firebase
const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
