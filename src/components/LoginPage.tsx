import React, { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Loader2, Hotel } from 'lucide-react';

export const LoginPage: React.FC = () => {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    try {
      await login(email, password);
    } catch (error) {
      console.error('Erro no login:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-[hsl(var(--geometric-blue-light))]/5 p-4 relative overflow-hidden">
      {/* Elementos geométricos de fundo inspirados na imagem */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-10 left-10 w-32 h-32 bg-[var(--luxury-gradient)] rounded transform rotate-12 opacity-5 animate-pulse"></div>
        <div className="absolute top-20 right-20 w-24 h-24 bg-[hsl(var(--geometric-blue-light))] rounded-full opacity-10 animate-pulse" style={{animationDelay: '1s'}}></div>
        <div className="absolute bottom-20 left-20 w-16 h-16 bg-[hsl(var(--geometric-dark))] rounded transform rotate-45 opacity-5 animate-pulse" style={{animationDelay: '2s'}}></div>
        <div className="absolute bottom-10 right-10 w-40 h-40 bg-[var(--geometric-gradient)] rounded-full opacity-5 animate-pulse" style={{animationDelay: '0.5s'}}></div>
        <div className="absolute top-1/2 left-1/4 w-8 h-8 bg-[hsl(var(--geometric-blue))] rounded opacity-10 animate-pulse" style={{animationDelay: '1.5s'}}></div>
        <div className="absolute top-1/3 right-1/3 w-12 h-12 bg-[hsl(var(--geometric-blue-light))] rounded-full opacity-5 animate-pulse" style={{animationDelay: '2.5s'}}></div>
        
        {/* Elementos geométricos adicionais para mais elegância */}
        <div className="absolute top-1/4 left-1/2 w-6 h-6 bg-[hsl(var(--geometric-blue))] rounded-full opacity-5 animate-pulse" style={{animationDelay: '3s'}}></div>
        <div className="absolute bottom-1/3 left-1/3 w-20 h-20 bg-[var(--luxury-gradient)] rounded transform rotate-45 opacity-3 animate-pulse" style={{animationDelay: '0.8s'}}></div>
      </div>
      
      <Card className="w-full max-w-md shadow-[var(--card-shadow)] hover:shadow-[var(--card-hover-shadow)] transition-[var(--transition-smooth)] relative z-10 border-2 border-transparent bg-gradient-to-br from-white via-white to-[hsl(var(--geometric-blue-light))]/5 backdrop-blur-sm">
        <CardHeader className="text-center relative pb-8">
          {/* Elemento geométrico decorativo no header */}
          <div className="absolute top-0 right-0 w-20 h-20 opacity-8 pointer-events-none">
            <div className="absolute top-3 right-3 w-8 h-8 bg-[var(--luxury-gradient)] rounded transform rotate-45 animate-pulse"></div>
            <div className="absolute top-6 right-6 w-4 h-4 bg-[hsl(var(--geometric-blue-light))] rounded-full animate-pulse" style={{animationDelay: '1s'}}></div>
          </div>
          
          {/* Logo personalizada */}
          <div className="mx-auto mb-6 flex items-center justify-center">
            <img 
              src="/logo.svg" 
              alt="Logo" 
              className="h-24 w-24 drop-shadow-lg hover:scale-105 transition-transform duration-300"
              onError={(e) => {
                console.error('Erro ao carregar logo:', e);
                e.currentTarget.style.display = 'none';
              }}
              onLoad={() => console.log('Logo carregada com sucesso')}
            />
          </div>
          
          <CardTitle className="text-3xl bg-gradient-to-r from-[hsl(var(--geometric-blue))] to-[hsl(var(--geometric-dark))] bg-clip-text text-transparent mb-2">
            Bem-vindo
          </CardTitle>
          <CardDescription className="text-base text-muted-foreground">
            Faça login para acessar o sistema de campanhas
          </CardDescription>
        </CardHeader>
        
        <CardContent className="pt-0">
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="email" className="text-sm font-medium text-[hsl(var(--geometric-dark))]">
                Email
              </Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Digite seu email"
                required
                disabled={isLoading}
                className="h-12 focus:ring-2 focus:ring-[hsl(var(--geometric-blue))] focus:border-[hsl(var(--geometric-blue))] border-2 transition-all duration-300"
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="password" className="text-sm font-medium text-[hsl(var(--geometric-dark))]">
                Senha
              </Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Digite sua senha"
                required
                disabled={isLoading}
                className="h-12 focus:ring-2 focus:ring-[hsl(var(--geometric-blue))] focus:border-[hsl(var(--geometric-blue))] border-2 transition-all duration-300"
              />
            </div>
            
            <Button 
              type="submit" 
              className="w-full h-12 text-lg font-medium" 
              disabled={isLoading}
            >
              {isLoading && <Loader2 className="mr-2 h-5 w-5 animate-spin" />}
              {isLoading ? 'Entrando...' : 'Entrar'}
            </Button>
          </form>
          
          {/* Elemento decorativo no rodapé */}
          <div className="mt-8 flex justify-center">
            <div className="w-16 h-1 bg-[var(--luxury-gradient)] rounded-full opacity-30"></div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};