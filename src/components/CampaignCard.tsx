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
      className="w-[360px] bg-white shadow-[0_4px_18px_rgba(0,0,0,0.08)] border-0 rounded-[12px] overflow-hidden group hover:scale-[1.02] hover:shadow-[0_6px_24px_rgba(0,0,0,0.12)] transition-[var(--transition-smooth)] flex flex-col flex-shrink-0 cursor-pointer relative"
      onClick={handleReserve}
    >
      {/* Imagem ajustada para 210px conforme modelo */}
      <div className="relative h-[210px] overflow-hidden">
        <img 
          src={campaign.image} 
          alt={campaign.title}
          className="w-full h-full object-cover block group-hover:scale-105 transition-transform duration-300"
        />
        
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
      
      {/* Wave SVG - 30px height conforme modelo */}
      <svg className="block w-full h-[30px]" viewBox="0 0 500 50" preserveAspectRatio="none">
        <defs>
          <linearGradient id={`waveGradient-${campaign.id}`} x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor={campaign.waveColor || 'hsl(var(--geometric-blue))'} />
            <stop offset="100%" stopColor={campaign.waveColor ? campaign.waveColor : 'hsl(var(--geometric-dark))'} />
          </linearGradient>
        </defs>
        <path d="M0,30 C150,60 350,0 500,30 L500,00 L0,0 Z" fill={`url(#waveGradient-${campaign.id})`}></path>
      </svg>

      {/* Conteúdo do card conforme modelo */}
      <div className="px-[18px] pt-[16px] pb-[18px] flex flex-col">
        {/* .card-title – Título – 18px – 6px margin-bottom */}
        <div className="text-[18px] font-bold mb-[6px] text-[#222] leading-[1.2] line-clamp-1" style={{ fontFamily: 'Arial, sans-serif' }}>
          {campaign.title}
        </div>
        
        {/* .card-label – A partir de – 13px – 2px margin-bottom */}
        <div className="text-[13px] text-[#888] mb-[2px] leading-[1.4]" style={{ fontFamily: 'Arial, sans-serif' }}>
          A partir de
        </div>
        
        {/* .card-price – R$ 1.834,00 – 24px – 6px margin-bottom */}
        <div className="text-[24px] font-bold mb-[6px] text-[#000] leading-[1.1] flex items-center gap-2" style={{ fontFamily: 'Arial, sans-serif' }}>
          {campaign.pricePromotional && campaign.pricePromotional > 0 && campaign.pricePromotional < campaign.priceOriginal ? (
            <>
              <span className="line-through text-gray-500">{formatPrice(campaign.priceOriginal)}</span>
              <span>{formatPrice(campaign.pricePromotional)}</span>
            </>
          ) : (
            <span>{formatPrice(campaign.priceOriginal)}</span>
          )}
        </div>
        
        {/* .card-sub – Diária para dois adultos – 14px – 12px margin-bottom */}
        <div className="text-[14px] font-bold mb-[12px] text-[#000] leading-[1.4] line-clamp-1" style={{ fontFamily: 'Arial, sans-serif' }}>
          {campaign.description || 'Diária para dois adultos'}
        </div>
        
        {/* Informações com ícones - .card-info */}
        <div className="flex flex-col">
          {(campaign.startDate && campaign.endDate) && (
            <div className="flex items-center gap-[6px] text-[#333] text-[14px] leading-[1.4] mb-[6px]" style={{ fontFamily: 'Arial, sans-serif' }}>
              <Calendar className="w-4 h-4 fill-none stroke-[#444] stroke-[1.5] flex-shrink-0" />
              <span className="truncate">{formatDate(campaign.startDate)} até {formatDate(campaign.endDate)}</span>
            </div>
          )}
          {/* .card-info último item – 0px margin-bottom */}
          <div className="flex items-center gap-[6px] text-[#333] text-[14px] leading-[1.4] mb-0" style={{ fontFamily: 'Arial, sans-serif' }}>
            <Bed className="w-4 h-4 fill-none stroke-[#444] stroke-[1.5] flex-shrink-0" />
            <span className="truncate">{getDurationText(calculateNights())}</span>
          </div>
        </div>
      </div>
    </Card>
  );
};