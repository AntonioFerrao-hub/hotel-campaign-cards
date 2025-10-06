import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Campaign, Category } from '@/types/campaign';
import { supabase } from '@/integrations/supabase/client';

interface CampaignContextType {
  campaigns: Campaign[];
  addCampaign: (campaign: Omit<Campaign, 'id'>) => Promise<Campaign>;
  updateCampaign: (id: string, campaign: Partial<Campaign>) => Promise<void>;
  deleteCampaign: (id: string) => void;
  getCampaign: (id: string) => Campaign | undefined;
  loading: boolean;
  refetch: () => Promise<void>;
}

const CampaignContext = createContext<CampaignContextType | undefined>(undefined);

export const useCampaigns = () => {
  const context = useContext(CampaignContext);
  if (context === undefined) {
    throw new Error('useCampaigns must be used within a CampaignProvider');
  }
  return context;
};

interface CampaignProviderProps {
  children: ReactNode;
}

export const CampaignProvider: React.FC<CampaignProviderProps> = ({ children }) => {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchCampaignCategories = async (campaignId: string): Promise<Category[]> => {
    try {
      const { data, error } = await supabase
        .from('campaign_categories')
        .select(`
          categories (
            id,
            name,
            description
          )
        `)
        .eq('campaign_id', campaignId);

      if (error) {
        console.error('Error fetching campaign categories:', error);
        return [];
      }

      return (data || []).map((item: any) => item.categories).filter(Boolean);
    } catch (error) {
      console.error('Unexpected error fetching campaign categories:', error);
      return [];
    }
  };

  const fetchCampaigns = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('campaigns')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Erro ao buscar campanhas:', error);
        return;
      }

      // Mapear dados do Supabase para o formato esperado e buscar categorias
      const mappedCampaigns: Campaign[] = await Promise.all(
        (data || []).map(async (campaign) => {
          const categories = await fetchCampaignCategories(campaign.id);
          
          return {
            id: campaign.id,
            title: campaign.title,
            description: campaign.description || 'Diária para dois adultos',
            priceOriginal: campaign.price_original || 0,
            pricePromotional: campaign.price_promotional || 0,
            priceLabel: campaign.price_label || 'A partir de',
            image: campaign.image_url || '/placeholder.svg',
            startDate: campaign.start_date || '',
            endDate: campaign.end_date || '',
            duration: campaign.duration_nights ? `${campaign.duration_nights} diárias` : '2 diárias',
            status: campaign.is_active ? 'active' : 'inactive',
            category: campaign.category || '',
            location: '',
            maxGuests: 0,
            bookingUrl: campaign.booking_url || '',
            waveColor: campaign.wave_color || '#3B82F6',
            categories: categories
          };
        })
      );

      setCampaigns(mappedCampaigns);
    } catch (error) {
      console.error('Erro inesperado ao buscar campanhas:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCampaigns();
  }, []);

  const addCampaign = async (campaign: Omit<Campaign, 'id'>): Promise<Campaign> => {
    try {
      // Calcular duration_nights a partir das datas
      let durationNights = 2; // valor padrão
      if (campaign.startDate && campaign.endDate) {
        const startDate = new Date(campaign.startDate);
        const endDate = new Date(campaign.endDate);
        const diffTime = endDate.getTime() - startDate.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); // Número de noites (sem +1)
        if (diffDays > 0) {
          durationNights = diffDays;
        }
      }

      const { data, error } = await supabase
        .from('campaigns')
        .insert({
          title: campaign.title,
          description: campaign.description,
          price_original: campaign.priceOriginal,
          price_promotional: campaign.pricePromotional,
          price_label: campaign.priceLabel,
          start_date: campaign.startDate,
          end_date: campaign.endDate,
          duration_nights: durationNights,
          is_active: campaign.status === 'active',
          image_url: campaign.image,
          category: campaign.category,
          booking_url: campaign.bookingUrl,
          wave_color: campaign.waveColor || '#3B82F6'
        })
        .select('*')
        .single();

      if (error) {
        throw error;
      }

      // Create the campaign object to return
      const newCampaign: Campaign = {
        id: data.id,
        title: data.title,
        description: data.description || 'Diária para dois adultos',
        priceOriginal: data.price_original || 0,
        pricePromotional: data.price_promotional || 0,
        priceLabel: data.price_label || 'A partir de',
        image: data.image_url || '/placeholder.svg',
        startDate: data.start_date || '',
        endDate: data.end_date || '',
        duration: data.duration_nights ? `${data.duration_nights} diárias` : '2 diárias',
        status: data.is_active ? 'active' : 'inactive',
        category: data.category || '',
        location: '',
        maxGuests: 0,
        bookingUrl: data.booking_url || '',
        waveColor: data.wave_color || '#3B82F6',
        categories: campaign.categories || []
      };

      // Recarrega as campanhas imediatamente após a inserção
      await fetchCampaigns();
      
      return newCampaign;
    } catch (error) {
      console.error('Erro ao adicionar campanha:', error);
      throw error;
    }
  };

  const updateCampaign = async (id: string, updatedCampaign: Partial<Campaign>) => {
    try {
      // Calcular duration_nights a partir das datas se foram fornecidas
      let updateData: any = {
        title: updatedCampaign.title,
        description: updatedCampaign.description,
        price_original: updatedCampaign.priceOriginal,
        price_promotional: updatedCampaign.pricePromotional,
        price_label: updatedCampaign.priceLabel,
        start_date: updatedCampaign.startDate,
        end_date: updatedCampaign.endDate,
        is_active: updatedCampaign.status === 'active',
        image_url: updatedCampaign.image,
        category: updatedCampaign.category,
        booking_url: updatedCampaign.bookingUrl,
        wave_color: updatedCampaign.waveColor
      };

      if (updatedCampaign.startDate && updatedCampaign.endDate) {
        const startDate = new Date(updatedCampaign.startDate);
        const endDate = new Date(updatedCampaign.endDate);
        const diffTime = endDate.getTime() - startDate.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); // Número de noites (sem +1)
        if (diffDays > 0) {
          updateData.duration_nights = diffDays;
        }
      }

      const { data, error } = await supabase
        .from('campaigns')
        .update(updateData)
        .eq('id', id)
        .select('*');

      if (error) {
        throw error;
      }

      // Recarrega as campanhas imediatamente após a atualização
      await fetchCampaigns();
      
    } catch (error) {
      console.error('Erro ao atualizar campanha:', error);
      throw error;
    }
  };

  const deleteCampaign = (id: string) => {
    setCampaigns(prev => prev.filter(campaign => campaign.id !== id));
  };

  const getCampaign = (id: string) => {
    return campaigns.find(campaign => campaign.id === id);
  };

  return (
    <CampaignContext.Provider value={{
      campaigns,
      addCampaign,
      updateCampaign,
      deleteCampaign,
      getCampaign,
      loading,
      refetch: fetchCampaigns
    }}>
      {children}
    </CampaignContext.Provider>
  );
};