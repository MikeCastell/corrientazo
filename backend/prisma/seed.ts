import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  // Seed idempotente: usa upsert por claves únicas.

  // 1) Sanitary levels mínimos (0 y 1) para que el sistema pueda crecer.
  await prisma.sanitary_levels.upsert({
    where: { level_number: 0 },
    update: {},
    create: {
      level_number: 0,
      name: "Nivel 0",
      description: "Registro básico",
      checklist_json: { items: [] },
    },
  });

  await prisma.sanitary_levels.upsert({
    where: { level_number: 1 },
    update: {},
    create: {
      level_number: 1,
      name: "Nivel 1",
      description: "Checklist básico",
      checklist_json: {
        items: [
          { id: "handwashing", label: "Lavado de manos", type: "checkbox" },
          { id: "clean_surface", label: "Superficies limpias", type: "checkbox" },
        ],
      },
    },
  });

  // 2) Usuario admin básico (para backoffice futuro).
  const admin = await prisma.users.upsert({
    where: { phone: "+570000000000" },
    update: {},
    create: {
      phone: "+570000000000",
      name: "Admin",
      role: "ADMIN",
      status: "ACTIVE",
    },
    select: { id: true },
  });

  // Password admin (solo para foundation local; en producción se cambia a OTP)
  const adminPwdHash = await bcrypt.hash("ChangeMe123!", 12);
  await prisma.auth_passwords.upsert({
    where: { user_id: admin.id },
    update: { password_hash: adminPwdHash },
    create: {
      user_id: admin.id,
      password_hash: adminPwdHash
    },
  });
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });

