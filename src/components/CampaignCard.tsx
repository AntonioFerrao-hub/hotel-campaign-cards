import React from 'react';
import { Campaign } from '@/types/campaign';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Calendar, Bed, Edit, Trash2 } from 'lucide-react';
import { useCampaigns } from '@/contexts/CampaignContext';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { useNavigate } from 'react-router-dom';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

interface CampaignCardProps {
  campaign: Campaign;
  onEdit?: (campaign: Campaign) => void;
  showActions?: boolean;
}

export const CampaignCard: React.FC<CampaignCardProps> = ({ 
  campaign, 
  onEdit, 
  showActions = true 
}) => {
  const { deleteCampaign } = useCampaigns();
  const { toast } = useToast();
  const navigate = useNavigate();

  const handleReserve = () => {
    if (campaign.bookingUrl) {
      // Redirecionar para o link de reserva da campanha
      window.open(campaign.bookingUrl, '_blank');
    } else {
      // Mostrar toast se não houver link configurado
      toast({
        title: "Link não configurado",
        description: "Esta campanha ainda não possui um link de reserva configurado.",
        variant: "destructive",
      });
    }
  };

  const handleDelete = async () => {
    try {
      const { error } = await supabase
        .from('campaigns')
        .delete()
        .eq('id', campaign.id);

      if (error) {
        console.error('Erro ao deletar campanha:', error);
        toast({
          title: "Erro",
          description: "Erro ao deletar a campanha. Tente novamente.",
          variant: "destructive",
        });
        return;
      }

      // Atualiza o context local também
      deleteCampaign(campaign.id);
      
      toast({
        title: "Campanha excluída",
        description: `A campanha "${campaign.title}" foi excluída com sucesso.`,
      });
    } catch (error) {
      console.error('Erro inesperado ao deletar campanha:', error);
      toast({
        title: "Erro",
        description: "Erro inesperado ao deletar a campanha.",
        variant: "destructive",
      });
    }
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(price);
  };

  const formatDate = (dateString: string) => {
    if (!dateString) return '';
    
    // Parse the date string directly to avoid timezone issues
    const [year, month, day] = dateString.split('-');
    const date = new Date(parseInt(year), parseInt(month) - 1, parseInt(day));
    
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const getDurationText = (nights: number) => {
    if (nights === 1) return '1 diária';
    return `${nights} diárias`;
  };

  // Calcular número de noites entre as datas
  const calculateNights = () => {
    if (!campaign.startDate || !campaign.endDate) return 2;
    const start = new Date(campaign.startDate);
    const end = new Date(campaign.endDate);
    
    // Validar se as datas são válidas
    if (isNaN(start.getTime()) || isNaN(end.getTime())) return 2;
    
    const diffTime = end.getTime() - start.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1; // +1 para incluir ambos os dias
    return diffDays > 0 ? diffDays : 2;
  };

  return (
    <Card 
      className="w-[360px] h-[450px] bg-white shadow-[var(--card-shadow)] border border-gray-200 rounded-[10px] overflow-hidden group hover:scale-[1.02] hover:shadow-[var(--card-hover-shadow)] transition-[var(--transition-smooth)] flex flex-col flex-shrink-0 cursor-pointer relative"
      onClick={handleReserve}
    >
      {/* Elementos geométricos decorativos inspirados na imagem */}
      <div className="absolute top-0 right-0 w-16 h-16 opacity-10 pointer-events-none">
        <div className="absolute top-2 right-2 w-8 h-8 bg-gradient-to-br from-[hsl(var(--geometric-blue))] to-[hsl(var(--geometric-dark))] rounded transform rotate-45"></div>
        <div className="absolute top-6 right-6 w-4 h-4 bg-[hsl(var(--geometric-blue-light))] rounded-full"></div>
      </div>
      
      {/* Imagem ajustada para 240px + onda 30px = 270px total */}
        <div className="relative h-[240px] overflow-hidden">
        <img 
          src={campaign.image} 
          alt={campaign.title}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300 brightness-105 contrast-105"
        />
        {/* Overlay com gradiente geométrico */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/10 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
        <div className="absolute inset-0 bg-[var(--geometric-gradient)] opacity-0 group-hover:opacity-5 transition-opacity duration-300"></div>
        
        {showActions && (
          <div className="absolute top-2 right-2 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <Button
              size="sm"
              variant="secondary"
              onClick={(e) => {
                e.stopPropagation();
                onEdit?.(campaign);
              }}
              className="h-7 w-7 p-0 bg-white/90 hover:bg-white backdrop-blur-sm"
            >
              <Edit className="h-3 w-3" />
            </Button>
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button
                  size="sm"
                  variant="destructive"
                  onClick={(e) => e.stopPropagation()}
                  className="h-7 w-7 p-0 bg-red-500/90 hover:bg-red-500 backdrop-blur-sm"
                >
                  <Trash2 className="h-3 w-3" />
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Excluir campanha</AlertDialogTitle>
                  <AlertDialogDescription>
                    Tem certeza que deseja excluir a campanha "{campaign.title}"? Esta ação não pode ser desfeita.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancelar</AlertDialogCancel>
                  <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                    Excluir
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        )}
      </div>
      
      {/* Wave SVG com gradiente geométrico */}
      <svg className="block w-full h-[30px] m-0 p-0" viewBox="0 0 500 50" preserveAspectRatio="none">
        <defs>
          <linearGradient id={`waveGradient-${campaign.id}`} x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor={campaign.waveColor || 'hsl(var(--geometric-blue))'} />
            <stop offset="100%" stopColor={campaign.waveColor ? campaign.waveColor : 'hsl(var(--geometric-dark))'} />
          </linearGradient>
        </defs>
        <path d="M0,30 C150,60 350,0 500,30 L500,00 L0,0 Z" fill={`url(#waveGradient-${campaign.id})`}></path>
      </svg>

      {/* Conteúdo do card com min-height de 180px para flexibilidade */}
      <div className="min-h-[180px] p-4 flex flex-col justify-between overflow-hidden relative">
        {/* Elemento geométrico sutil no fundo */}
        <div className="absolute bottom-0 left-0 w-12 h-12 opacity-5 pointer-events-none">
          <div className="w-full h-full bg-[var(--luxury-gradient)] rounded-tr-full"></div>
        </div>
        
        <div className="flex flex-col relative z-10">
          {/* .title – Setembro 2025 – 18px – 8px margin-bottom */}
          <div className="text-[18px] font-bold mb-[8px] text-gray-900 leading-tight line-clamp-1">
            {campaign.title}
          </div>
          
          {/* .label – A partir de – 13px – 2px margin-bottom */}
          <div className="text-[13px] text-gray-500 mb-[2px]">
            A partir de
          </div>
          
          {/* .price – R$ 1.834,00 – 24px – 5px margin-bottom com gradiente sutil */}
          <div className="text-[24px] font-bold bg-gradient-to-r from-[hsl(var(--geometric-blue))] to-[hsl(var(--geometric-dark))] bg-clip-text text-transparent mb-[5px]">
            {formatPrice(campaign.pricePromotional || campaign.priceOriginal)}
          </div>
          
          {/* .sub – Diária para dois adultos – 14px – 15px margin-bottom */}
          <div className="text-[14px] font-bold mb-[15px] line-clamp-1">
            {campaign.description || 'Diária para dois adultos'}
          </div>
        </div>
        
        {/* Informações com ícones - 14px - fixadas na parte inferior */}
        <div className="flex flex-col relative z-10">
          {(campaign.startDate && campaign.endDate) && (
            <div className="flex items-center text-[14px] text-gray-700 mb-[4px]">
              <Calendar className="w-4 h-4 mr-1 fill-[hsl(var(--geometric-blue-light))]" />
              <span className="truncate">{formatDate(campaign.startDate)} até {formatDate(campaign.endDate)}</span>
            </div>
          )}
          {/* .info – 2 diárias (último item) – 14px – 0px margin-bottom */}
          <div className="flex items-center text-[14px] text-gray-700 font-bold mb-[0px]">
            <Bed className="w-4 h-4 mr-1 fill-[hsl(var(--geometric-blue-light))]" />
            <span className="truncate">{getDurationText(calculateNights())}</span>
          </div>
        </div>
      </div>
    </Card>
  );
};