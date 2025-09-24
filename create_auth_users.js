// ========================================
// SCRIPT PARA MIGRAR USUÁRIOS PARA AUTH.USERS
// ========================================

import { createClient } from '@supabase/supabase-js';
// Configurações do Supabase
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'your-service-role-key';

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Variáveis de ambiente VITE_SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórias');
  process.exit(1);
}

// Cliente Supabase com service role key para operações administrativas
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function migrateUsersToAuth() {
  try {
    console.log('🔍 Buscando usuários na tabela profiles...');
    
    // Buscar todos os usuários da tabela profiles
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at');

    if (profilesError) {
      throw new Error(`Erro ao buscar profiles: ${profilesError.message}`);
    }

    console.log(`📊 Encontrados ${profiles.length} usuários na tabela profiles`);

    // Verificar quais usuários já existem em auth.users
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();
    
    if (authError) {
      throw new Error(`Erro ao listar usuários auth: ${authError.message}`);
    }

    const existingAuthEmails = new Set(authUsers.users.map(user => user.email));
    console.log(`📊 Encontrados ${authUsers.users.length} usuários em auth.users`);

    let createdCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    // Migrar cada usuário
    for (const profile of profiles) {
      try {
        if (existingAuthEmails.has(profile.email)) {
          console.log(`⏭️  Usuário ${profile.email} já existe em auth.users`);
          skippedCount++;
          continue;
        }

        // Criar usuário em auth.users
        const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
          email: profile.email,
          password: 'TempPassword123!', // Senha temporária - usuário deve redefinir
          email_confirm: true,
          user_metadata: {
            name: profile.name,
            role: profile.role
          }
        });

        if (createError) {
          console.error(`❌ Erro ao criar usuário ${profile.email}:`, createError.message);
          errorCount++;
          continue;
        }

        // Atualizar o ID do profile para corresponder ao ID do auth.users
        const { error: updateError } = await supabase
          .from('profiles')
          .update({ id: newUser.user.id })
          .eq('email', profile.email);

        if (updateError) {
          console.error(`⚠️  Usuário criado mas erro ao atualizar profile ${profile.email}:`, updateError.message);
        }

        console.log(`✅ Usuário ${profile.email} migrado com sucesso`);
        createdCount++;

      } catch (error) {
        console.error(`❌ Erro inesperado ao migrar ${profile.email}:`, error.message);
        errorCount++;
      }
    }

    console.log('\n📈 RESUMO DA MIGRAÇÃO:');
    console.log(`✅ Usuários criados: ${createdCount}`);
    console.log(`⏭️  Usuários já existentes: ${skippedCount}`);
    console.log(`❌ Erros: ${errorCount}`);
    console.log(`📊 Total processado: ${profiles.length}`);

    if (createdCount > 0) {
      console.log('\n🔐 IMPORTANTE:');
      console.log('- Todos os usuários migrados receberam a senha temporária: TempPassword123!');
      console.log('- Eles devem redefinir suas senhas no primeiro login');
      console.log('- Execute o script de sincronização SQL para garantir consistência');
    }

  } catch (error) {
    console.error('❌ Erro geral na migração:', error.message);
    process.exit(1);
  }
}

// Executar migração
console.log('🚀 Iniciando migração de usuários...\n');
migrateUsersToAuth()
  .then(() => {
    console.log('\n🎉 Migração concluída!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Falha na migração:', error.message);
    process.exit(1);
  });