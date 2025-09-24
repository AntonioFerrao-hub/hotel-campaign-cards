#!/usr/bin/env node

// Script para testar login do usuário suporte@wfinformatica.com.br
import { createClient } from '@supabase/supabase-js';

// Configurações do Supabase
const supabaseUrl = 'https://mpdblvvznqpajascuxxb.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZGJsdnZ6bnFwYWphc2N1eHhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3MjYyOTEsImV4cCI6MjA1NzMwMjI5MX0.8bFGtwYMWwkaHNtZD2-zNYoN-Tvp_cVdiaCjpmkPzJ0';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testSuporteLogin() {
  console.log('🔍 Testando login do usuário suporte@wfinformatica.com.br');
  console.log('=' .repeat(60));

  const email = 'suporte@wfinformatica.com.br';
  const password = 'senha123';

  try {
    // 1. Verificar se usuário existe em auth.users
    console.log('\n1️⃣ Verificando usuário em auth.users...');
    
    // Não podemos consultar auth.users diretamente com chave anon
    // Vamos tentar fazer login para verificar se existe
    
    // 2. Tentar login
    console.log('\n2️⃣ Tentando fazer login...');
    const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
      email: email,
      password: password
    });

    if (loginError) {
      console.log('❌ Erro no login:', loginError.message);
      console.log('📋 Detalhes do erro:', loginError);
      
      // Verificar tipos específicos de erro
      if (loginError.message === 'Invalid login credentials') {
        console.log('\n🔍 Possíveis causas:');
        console.log('   • Usuário não existe em auth.users');
        console.log('   • Senha incorreta');
        console.log('   • Email não confirmado');
      }
      
      return false;
    }

    if (!loginData.user) {
      console.log('❌ Login falhou - nenhum usuário retornado');
      return false;
    }

    console.log('✅ Login realizado com sucesso!');
    console.log('👤 Usuário ID:', loginData.user.id);
    console.log('📧 Email:', loginData.user.email);
    console.log('📅 Criado em:', loginData.user.created_at);
    console.log('🔐 Email confirmado:', loginData.user.email_confirmed_at ? 'Sim' : 'Não');

    // 3. Verificar se existe profile correspondente
    console.log('\n3️⃣ Verificando profile correspondente...');
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', loginData.user.id)
      .single();

    if (profileError) {
      console.log('❌ Erro ao buscar profile:', profileError.message);
      console.log('⚠️  O usuário existe em auth.users mas NÃO tem profile correspondente');
      
      // Verificar se existe profile com o mesmo email
      const { data: profileByEmail, error: profileByEmailError } = await supabase
        .from('profiles')
        .select('*')
        .eq('email', email)
        .single();

      if (profileByEmailError) {
        console.log('❌ Também não existe profile com este email');
      } else {
        console.log('⚠️  Existe profile com este email mas ID diferente:');
        console.log('   Profile ID:', profileByEmail.id);
        console.log('   Auth User ID:', loginData.user.id);
      }
    } else {
      console.log('✅ Profile encontrado!');
      console.log('👤 Nome:', profile.name);
      console.log('📧 Email:', profile.email);
      console.log('🎭 Role:', profile.role);
      console.log('📅 Criado em:', profile.created_at);
    }

    // 4. Fazer logout
    console.log('\n4️⃣ Fazendo logout...');
    await supabase.auth.signOut();
    console.log('✅ Logout realizado');

    return true;

  } catch (error) {
    console.log('❌ Erro inesperado:', error.message);
    console.log('📋 Stack trace:', error.stack);
    return false;
  }
}

async function checkProfilesTable() {
  console.log('\n📊 Verificando tabela profiles...');
  console.log('=' .repeat(40));

  try {
    // Listar todos os profiles
    const { data: profiles, error } = await supabase
      .from('profiles')
      .select('id, name, email, role, created_at')
      .order('created_at', { ascending: false });

    if (error) {
      console.log('❌ Erro ao consultar profiles:', error.message);
      return;
    }

    console.log(`📋 Total de profiles encontrados: ${profiles.length}`);
    
    if (profiles.length > 0) {
      console.log('\n👥 Profiles existentes:');
      profiles.forEach((profile, index) => {
        console.log(`   ${index + 1}. ${profile.name} (${profile.email}) - ${profile.role}`);
      });

      // Verificar se existe o usuário suporte
      const suporteProfile = profiles.find(p => p.email === 'suporte@wfinformatica.com.br');
      if (suporteProfile) {
        console.log('\n✅ Profile do suporte encontrado:');
        console.log('   ID:', suporteProfile.id);
        console.log('   Nome:', suporteProfile.name);
        console.log('   Email:', suporteProfile.email);
        console.log('   Role:', suporteProfile.role);
      } else {
        console.log('\n❌ Profile do suporte NÃO encontrado');
      }
    } else {
      console.log('⚠️  Nenhum profile encontrado na tabela');
    }

  } catch (error) {
    console.log('❌ Erro inesperado ao verificar profiles:', error.message);
  }
}

// Executar testes
async function main() {
  console.log('🚀 Iniciando verificação do usuário suporte@wfinformatica.com.br');
  console.log('🕐 Data/Hora:', new Date().toLocaleString('pt-BR'));
  
  // Primeiro verificar a tabela profiles
  await checkProfilesTable();
  
  // Depois testar o login
  await testSuporteLogin();
  
  console.log('\n🏁 Verificação concluída!');
}

main().catch(console.error);