import React from 'react';
import { Campaign } from '@/types/campaign';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Calendar, Clock, Edit, Trash2 } from 'lucide-react';
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

  return (
    <Card className="group overflow-hidden bg-card hover:shadow-[var(--card-hover-shadow)] transition-[var(--transition-smooth)] border-border">
      <div className="relative aspect-[16/10] overflow-hidden">
        <img 
          src={campaign.image} 
          alt={campaign.title}
          className="w-full h-full object-cover group-hover:scale-105 transition-[var(--transition-smooth)]"
        />
        <Badge 
          variant={campaign.status === 'active' ? 'default' : 'secondary'}
          className="absolute top-3 left-3"
        >
          {campaign.status === 'active' ? 'Ativa' : 'Inativa'}
        </Badge>
        {showActions && (
          <div className="absolute top-3 right-3 flex gap-2 opacity-0 group-hover:opacity-100 transition-[var(--transition-smooth)]">
            <Button
              size="sm"
              variant="secondary"
              onClick={() => onEdit?.(campaign)}
              className="h-8 w-8 p-0"
            >
              <Edit className="h-4 w-4" />
            </Button>
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button
                  size="sm"
                  variant="destructive"
                  className="h-8 w-8 p-0"
                >
                  <Trash2 className="h-4 w-4" />
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
      
      <div className="p-6">
        <div className="mb-3">
          <h3 className="font-semibold text-lg text-card-foreground mb-1">
            {campaign.title}
          </h3>
          <Badge variant="outline" className="text-xs">
            {campaign.category || 'Sem categoria'}
          </Badge>
        </div>
        
        <div className="mb-4">
          <p className="text-sm text-muted-foreground mb-2">
            {campaign.priceLabel}
          </p>
          <div className="flex items-center gap-2">
            <p className="text-2xl font-bold text-ocean-primary">
              {formatPrice(campaign.pricePromotional)}
            </p>
            {campaign.priceOriginal > campaign.pricePromotional && (
              <p className="text-sm text-muted-foreground line-through">
                {formatPrice(campaign.priceOriginal)}
              </p>
            )}
          </div>
          <p className="text-sm text-muted-foreground">
            {campaign.description}
          </p>
        </div>
        
        <div className="space-y-2 text-sm text-muted-foreground">
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4" />
            <span>{campaign.startDate} até {campaign.endDate}</span>
          </div>
          <div className="flex items-center gap-2">
            <Clock className="h-4 w-4" />
            <span>{campaign.duration}</span>
          </div>
        </div>
      </div>
    </Card>
  );
};