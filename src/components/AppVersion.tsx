import React from 'react';
import { Badge } from '@/components/ui/badge';
import { GitBranch } from 'lucide-react';

interface AppVersionProps {
  className?: string;
}

export const AppVersion: React.FC<AppVersionProps> = ({ className = '' }) => {
  // Versão baseada na tag do GitHub - será atualizada automaticamente no build
  const version = import.meta.env.VITE_APP_VERSION || 'v0.2.6';
  
  return (
    <div className={`flex items-center gap-2 ${className}`}>
      <Badge 
        variant="outline" 
        className="text-xs bg-gradient-to-r from-blue-50 to-blue-100 border-blue-300 text-blue-700 hover:bg-blue-200 transition-colors"
      >
        <GitBranch className="h-3 w-3 mr-1" />
        {version}
      </Badge>
    </div>
  );
};