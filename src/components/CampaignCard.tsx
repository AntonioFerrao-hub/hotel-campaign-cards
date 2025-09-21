import React from 'react';
import { Campaign } from '@/types/campaign';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Calendar, Phone, Edit, Trash2 } from 'lucide-react';
import { useCampaigns } from '@/contexts/CampaignContext';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
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
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR');
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
    const diffTime = end.getTime() - start.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays > 0 ? diffDays : 2;
  };

  return (
    <Card className="w-full max-w-[280px] bg-white shadow-sm border border-gray-200 rounded-lg overflow-hidden group hover:shadow-md transition-shadow">
      {/* Imagem */}
      <div className="relative h-[160px] overflow-hidden">
        <img 
          src={campaign.image} 
          alt={campaign.title}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
        />
        {showActions && (
          <div className="absolute top-2 right-2 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <Button
              size="sm"
              variant="secondary"
              onClick={() => onEdit?.(campaign)}
              className="h-7 w-7 p-0 bg-white/90 hover:bg-white"
            >
              <Edit className="h-3 w-3" />
            </Button>
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button
                  size="sm"
                  variant="destructive"
                  className="h-7 w-7 p-0 bg-red-500/90 hover:bg-red-500"
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
      
      {/* Conteúdo */}
      <div className="p-4 space-y-3">
        {/* Título */}
        <h3 className="font-medium text-gray-900 text-sm leading-tight">
          {campaign.title}
        </h3>
        
        {/* Preço */}
        <div className="space-y-1">
          <p className="text-xs text-gray-500 uppercase tracking-wide">
            A partir de
          </p>
          <p className="text-lg font-bold text-gray-900">
            {formatPrice(campaign.pricePromotional || campaign.priceOriginal)}
          </p>
          <p className="text-xs text-gray-600">
            {campaign.description || 'Diária para dois adultos'}
          </p>
        </div>
        
        {/* Data e Duração */}
        <div className="space-y-2 text-xs text-gray-600">
          {(campaign.startDate && campaign.endDate) && (
            <div className="flex items-center gap-1">
              <Calendar className="h-3 w-3" />
              <span>{formatDate(campaign.startDate)} até {formatDate(campaign.endDate)}</span>
            </div>
          )}
          <div className="flex items-center gap-1">
            <Phone className="h-3 w-3" />
            <span>{getDurationText(calculateNights())}</span>
          </div>
        </div>
        
        {/* Botão Ver Detalhes para cards públicos */}
        {!showActions && (
          <Button className="w-full bg-teal-600 hover:bg-teal-700 text-white text-sm py-2 rounded-md">
            Ver Detalhes
          </Button>
        )}
      </div>
    </Card>
  );
};