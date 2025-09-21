import { Gallery } from '@/components/Gallery';
import { CampaignProvider } from '@/contexts/CampaignContext';

const Index = () => {
  return (
    <CampaignProvider>
      <Gallery />
    </CampaignProvider>
  );
};

export default Index;
