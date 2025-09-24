#!/usr/bin/env node

// Script para criar profile do usuário suporte@wfinformatica.com.br
import { createClient } from '@supabase/supabase-js';

// Configurações do Supabase
const supabaseUrl = 'https://mpdblvvznqpajascuxxb.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZGJsdnZ6bnFwYWphc2N1eHhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3MjYyOTEsImV4cCI6MjA1NzMwMjI5MX0.8bFGtwYMWwkaHNtZD2-zNYoN-Tvp_cVdiaCjpmkPzJ0';

const supabase = createClient(supabaseUrl, supabaseKey);

async function createSuporteProfile() {
  console.log('🔧 Criando profile para usuário suporte@wfinformatica.com.br');
  console.log('=' .repeat(60));

  const email = 'suporte@wfinformatica.com.br';
  const password = 'senha123';

  try {
    // 1. Fazer login para obter o ID do usuário
    console.log('\n1️⃣ Fazendo login para obter ID do usuário...');
    const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
      email: email,
      password: password
    });

    if (loginError) {
      console.log('❌ Erro no login:', loginError.message);
      return false;
    }

    if (!loginData.user) {
      console.log('❌ Login falhou - nenhum usuário retornado');
      return false;
    }

    console.log('✅ Login realizado com sucesso!');
    console.log('👤 Usuário ID:', loginData.user.id);

    // 2. Criar profile
    console.log('\n2️⃣ Criando profile...');
    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .upsert({
        id: loginData.user.id,
        name: 'Suporte WF Informática',
        email: email,
        role: 'admin'
      })
      .select()
      .single();

    if (profileError) {
      console.log('❌ Erro ao criar profile:', profileError.message);
      console.log('📋 Detalhes do erro:', profileError);
      return false;
    }

    console.log('✅ Profile criado com sucesso!');
    console.log('👤 Nome:', profileData.name);
    console.log('📧 Email:', profileData.email);
    console.log('🎭 Role:', profileData.role);
    console.log('🆔 ID:', profileData.id);

    // 3. Verificar se o profile foi criado corretamente
    console.log('\n3️⃣ Verificando profile criado...');
    const { data: verifyProfile, error: verifyError } = await supabase
      .from('profiles')
      .select('*')
      .eq('email', email)
      .single();

    if (verifyError) {
      console.log('❌ Erro ao verificar profile:', verifyError.message);
    } else {
      console.log('✅ Profile verificado com sucesso!');
      console.log('📋 Dados do profile:');
      console.log('   ID:', verifyProfile.id);
      console.log('   Nome:', verifyProfile.name);
      console.log('   Email:', verifyProfile.email);
      console.log('   Role:', verifyProfile.role);
      console.log('   Criado em:', verifyProfile.created_at);
      console.log('   Atualizado em:', verifyProfile.updated_at);
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

async function testLoginAfterProfile() {
  console.log('\n🧪 Testando login após criação do profile...');
  console.log('=' .repeat(50));

  const email = 'suporte@wfinformatica.com.br';
  const password = 'senha123';

  try {
    // Fazer login
    const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
      email: email,
      password: password
    });

    if (loginError) {
      console.log('❌ Erro no login:', loginError.message);
      return false;
    }

    console.log('✅ Login realizado com sucesso!');

    // Buscar profile
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', loginData.user.id)
      .single();

    if (profileError) {
      console.log('❌ Erro ao buscar profile:', profileError.message);
      return false;
    }

    console.log('✅ Profile encontrado!');
    console.log('👤 Nome:', profile.name);
    console.log('📧 Email:', profile.email);
    console.log('🎭 Role:', profile.role);

    // Logout
    await supabase.auth.signOut();
    console.log('✅ Logout realizado');

    return true;

  } catch (error) {
    console.log('❌ Erro inesperado no teste:', error.message);
    return false;
  }
}

// Executar
async function main() {
  console.log('🚀 Iniciando criação do profile para suporte@wfinformatica.com.br');
  console.log('🕐 Data/Hora:', new Date().toLocaleString('pt-BR'));
  
  const success = await createSuporteProfile();
  
  if (success) {
    console.log('\n🧪 Executando teste final...');
    await testLoginAfterProfile();
  }
  
  console.log('\n🏁 Processo concluído!');
}

main().catch(console.error);