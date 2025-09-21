import { Campaign } from '@/types/campaign';
import resortSunset from '@/assets/resort-sunset.jpg';
import beachResort from '@/assets/beach-resort.jpg';
import restaurant from '@/assets/restaurant.jpg';
import familyResort from '@/assets/family-resort.jpg';

export const mockCampaigns: Campaign[] = [
  {
    id: '1',
    title: 'Resort Sunset Paradise',
    description: 'Experiência única com vista privilegiada do por do sol',
    price: 1834,
    priceLabel: 'A partir de',
    image: resortSunset,
    startDate: '01/09/2025',
    endDate: '30/09/2025',
    duration: '2 diárias',
    status: 'active',
    category: 'Temporada',
    location: 'Búzios, RJ',
    maxGuests: 4
  },
  {
    id: '2',
    title: 'Beach Resort Premium',
    description: 'Resort à beira-mar com acesso exclusivo à praia',
    price: 1834,
    priceLabel: 'A partir de',
    image: beachResort,
    startDate: '08/09/2025',
    endDate: '15/09/2025',
    duration: '4 diárias',
    status: 'active',
    category: 'Promocional',
    location: 'Porto de Galinhas, PE',
    maxGuests: 6
  },
  {
    id: '3',
    title: 'Hotel Gastronômico',
    description: 'Festival culinário com chefs renomados',
    price: 2204,
    priceLabel: 'A partir de',
    image: restaurant,
    startDate: '14/09/2025',
    endDate: '21/09/2025',
    duration: '6 diárias',
    status: 'active',
    category: 'Gastronômico',
    location: 'São Paulo, SP',
    maxGuests: 2
  },
  {
    id: '4',
    title: 'Resort Família',
    description: 'Diversão garantida para toda a família',
    price: 1835,
    priceLabel: 'A partir de',
    image: familyResort,
    startDate: '14/09/2025',
    endDate: '19/09/2025',
    duration: '4 diárias',
    status: 'active',
    category: 'Temporada',
    location: 'Caldas Novas, GO',
    maxGuests: 8
  }
];