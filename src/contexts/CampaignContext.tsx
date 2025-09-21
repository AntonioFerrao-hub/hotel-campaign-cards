import React, { createContext, useContext, useState, ReactNode } from 'react';
import { Campaign } from '@/types/campaign';
import { mockCampaigns } from '@/data/mockData';

interface CampaignContextType {
  campaigns: Campaign[];
  addCampaign: (campaign: Omit<Campaign, 'id'>) => void;
  updateCampaign: (id: string, campaign: Partial<Campaign>) => void;
  deleteCampaign: (id: string) => void;
  getCampaign: (id: string) => Campaign | undefined;
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
  const [campaigns, setCampaigns] = useState<Campaign[]>(mockCampaigns);

  const addCampaign = (campaign: Omit<Campaign, 'id'>) => {
    const newCampaign: Campaign = {
      ...campaign,
      id: Date.now().toString()
    };
    setCampaigns(prev => [...prev, newCampaign]);
  };

  const updateCampaign = (id: string, updatedCampaign: Partial<Campaign>) => {
    setCampaigns(prev => 
      prev.map(campaign => 
        campaign.id === id ? { ...campaign, ...updatedCampaign } : campaign
      )
    );
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
      getCampaign
    }}>
      {children}
    </CampaignContext.Provider>
  );
};