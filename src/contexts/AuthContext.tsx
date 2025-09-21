import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface AuthUser {
  id: string;
  email: string;
  name: string;
  role: string;
}

interface AuthContextType {
  user: AuthUser | null;
  session: Session | null;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => void;
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
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  const fetchUserProfile = async (userId: string) => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (error) {
        console.error('Erro ao buscar perfil do usuário:', error);
        return null;
      }

      return {
        id: data.id,
        email: data.email,
        name: data.name,
        role: data.role
      };
    } catch (error) {
      console.error('Erro inesperado ao buscar perfil:', error);
      return null;
    }
  };

  useEffect(() => {
    // Set up auth state listener
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setSession(session);
        
        if (session?.user) {
          // Fetch user profile data
          setTimeout(async () => {
            const userProfile = await fetchUserProfile(session.user.id);
            setUser(userProfile);
            setLoading(false);
          }, 0);
        } else {
          setUser(null);
          setLoading(false);
        }
      }
    );

    // Check for existing session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      if (session?.user) {
        fetchUserProfile(session.user.id).then(userProfile => {
          setUser(userProfile);
          setLoading(false);
        });
      } else {
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      setLoading(true);
      
      // Try to verify password using the custom function
      const { data, error } = await supabase.rpc('verify_user_password', {
        user_email: email,
        user_password: password
      });

      if (error) {
        console.error('Erro na verificação da senha:', error);
        toast({
          title: "Erro de login",
          description: "Email ou senha incorretos.",
          variant: "destructive",
        });
        return false;
      }

      if (!data || data.length === 0) {
        toast({
          title: "Erro de login",
          description: "Email ou senha incorretos.",
          variant: "destructive",
        });
        return false;
      }

      // If password verification successful, set user data
      const userData = data[0].user_data as any;
      setUser({
        id: userData.id,
        email: userData.email,
        name: userData.name,
        role: userData.role
      });

      // Create a mock session for compatibility
      const mockSession = {
        user: { id: userData.id, email: userData.email },
        access_token: 'mock-token',
        token_type: 'bearer',
        expires_in: 3600,
        expires_at: Date.now() + 3600000,
        refresh_token: 'mock-refresh'
      } as Session;
      
      setSession(mockSession);

      toast({
        title: "Login realizado",
        description: `Bem-vindo, ${userData.name}!`,
      });

      return true;
    } catch (error) {
      console.error('Erro inesperado no login:', error);
      toast({
        title: "Erro",
        description: "Erro inesperado ao fazer login.",
        variant: "destructive",
      });
      return false;
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    setSession(null);
    toast({
      title: "Logout realizado",
      description: "Você foi desconectado com sucesso.",
    });
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