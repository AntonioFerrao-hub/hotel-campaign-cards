import { Campaign } from '@/types/campaign';
import resortSunset from '@/assets/resort-sunset.jpg';
import beachResort from '@/assets/beach-resort.jpg';
import restaurant from '@/assets/restaurant.jpg';
import familyResort from '@/assets/family-resort.jpg';

export const mockCampaigns: Campaign[] = [
  {
    id: '1',
    title: 'Setembro 2025',
    description: 'Diária para dois adultos',
    price: 1834,
    priceLabel: 'A partir de',
    image: resortSunset,
    startDate: '01/09/2025',
    endDate: '30/09/2025',
    duration: '2 diárias',
    status: 'active',
    category: 'Temporada'
  },
  {
    id: '2',
    title: 'Semana do Cliente',
    description: 'Diária para dois adultos',
    price: 1834,
    priceLabel: 'A partir de',
    image: beachResort,
    startDate: '08/09/2025',
    endDate: '15/09/2025',
    duration: '4 diárias',
    status: 'active',
    category: 'Promocional'
  },
  {
    id: '3',
    title: 'Festival Gastronômico Latino-Americano 2025',
    description: 'Diária para dois adultos',
    price: 2204,
    priceLabel: 'A partir de',
    image: restaurant,
    startDate: '14/09/2025',
    endDate: '21/09/2025',
    duration: '6 diárias',
    status: 'active',
    category: 'Gastronômico'
  },
  {
    id: '4',
    title: 'Primavera 2025',
    description: 'Diária para dois adultos',
    price: 1835,
    priceLabel: 'A partir de',
    image: familyResort,
    startDate: '14/09/2025',
    endDate: '19/09/2025',
    duration: '4 diárias',
    status: 'active',
    category: 'Temporada'
  }
];