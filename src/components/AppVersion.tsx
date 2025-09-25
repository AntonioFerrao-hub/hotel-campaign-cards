import React from 'react';
import { Badge } from '@/components/ui/badge';
import { GitBranch } from 'lucide-react';

interface AppVersionProps {
  className?: string;
}

export const AppVersion: React.FC<AppVersionProps> = ({ className = '' }) => {
  // Versão baseada na tag do GitHub - será atualizada automaticamente no build
  const version = import.meta.env.VITE_APP_VERSION || 'v0.2.0';
  
  return (
    <div className={`flex items-center gap-2 ${className}`}>
      <Badge 
        variant="outline" 
        className="text-xs bg-gradient-to-r from-[hsl(var(--geometric-blue-light))]/10 to-[hsl(var(--geometric-blue))]/10 border-[hsl(var(--geometric-blue-light))] text-[hsl(var(--geometric-blue))] hover:bg-[hsl(var(--geometric-blue-light))]/20 transition-colors"
      >
        <GitBranch className="h-3 w-3 mr-1" />
        {version}
      </Badge>
    </div>
  );
};