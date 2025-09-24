import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface AuthUser {
  id: string;
  email: string;
  name: string;
  role: string;
  user_metadata?: {
    role: string;
  };
}

interface CustomSession {
  user: AuthUser;
  expires_at: number;
}

interface AuthContextType {
  user: AuthUser | null;
  session: CustomSession | null;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => Promise<void>;
  isAuthenticated: boolean;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [session, setSession] = useState<CustomSession | null>(null);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  // Chave para armazenar sessão no localStorage
  const SESSION_KEY = 'hotel_auth_session';

  // Função para salvar sessão no localStorage
  const saveSession = (userData: AuthUser) => {
    const sessionData: CustomSession = {
      user: userData,
      expires_at: Date.now() + (24 * 60 * 60 * 1000) // 24 horas
    };
    
    localStorage.setItem(SESSION_KEY, JSON.stringify(sessionData));
    setUser(userData);
    setSession(sessionData);
  };

  // Função para limpar sessão
  const clearSession = () => {
    localStorage.removeItem(SESSION_KEY);
    setUser(null);
    setSession(null);
  };

  // Verificar sessão salva ao carregar
  useEffect(() => {
    const checkSavedSession = () => {
      try {
        const savedSession = localStorage.getItem(SESSION_KEY);
        if (savedSession) {
          const sessionData: CustomSession = JSON.parse(savedSession);
          
          // Verificar se a sessão não expirou
          if (sessionData.expires_at > Date.now()) {
            setUser(sessionData.user);
            setSession(sessionData);
          } else {
            // Sessão expirada, limpar
            clearSession();
          }
        }
      } catch (error) {
        console.error('Erro ao verificar sessão salva:', error);
        clearSession();
      } finally {
        setLoading(false);
      }
    };

    checkSavedSession();
  }, []);

  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      setLoading(true);
      
      // Autenticação usando a nova tabela 'user' e função authenticate_user
      const { data, error } = await supabase.rpc('authenticate_user', {
        user_email: email.trim(),
        user_password: password
      });

      if (error) {
        console.error('Erro na autenticação:', error);
        toast({
          title: "Erro de login",
          description: "Erro interno do servidor. Verifique se o script SQL foi executado no Supabase.",
          variant: "destructive",
        });
        return false;
      }

      // Verificar se a autenticação foi bem-sucedida
      if (!data || data.length === 0 || !data[0].success) {
        const message = data && data[0] ? data[0].message : "Email ou senha incorretos.";
        toast({
          title: "Erro de login",
          description: message,
          variant: "destructive",
        });
        return false;
      }

      const authResult = data[0];

      // Criar objeto do usuário autenticado
      const userData: AuthUser = {
        id: authResult.user_id,
        email: email.trim().toLowerCase(),
        name: authResult.user_name,
        role: authResult.user_role,
        user_metadata: {
          role: authResult.user_role
        }
      };

      // Salvar sessão
      saveSession(userData);

      toast({
        title: "Login realizado",
        description: `Bem-vindo, ${userData.name}!`,
      });

      return true;
    } catch (error) {
      console.error('Erro inesperado no login:', error);
      toast({
        title: "Erro",
        description: "Erro inesperado ao fazer login. Verifique se o sistema foi configurado corretamente.",
        variant: "destructive",
      });
      return false;
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    try {
      clearSession();
      
      toast({
        title: "Logout realizado",
        description: "Você foi desconectado com sucesso.",
      });
    } catch (error) {
      console.error('Erro inesperado no logout:', error);
    }
  };

  const isAuthenticated = !!user && !!session;

  return (
    <AuthContext.Provider value={{ 
      user, 
      session, 
      login, 
      logout, 
      isAuthenticated, 
      loading 
    }}>
      {children}
    </AuthContext.Provider>
  );
};