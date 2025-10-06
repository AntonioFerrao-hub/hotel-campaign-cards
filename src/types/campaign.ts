export interface Category {
  id: string;
  name: string;
  description?: string;
}

export interface Campaign {
  id: string;
  title: string;
  description: string;
  priceOriginal: number;
  pricePromotional: number;
  priceLabel: string;
  image: string;
  startDate: string;
  endDate: string;
  duration: string;
  status: 'active' | 'inactive';
  category: string; // Mantido para compatibilidade
  categories?: Category[]; // Nova propriedade para múltiplas categorias
  location: string;
  maxGuests: number;
  bookingUrl?: string;
  waveColor?: string; // Cor personalizada da onda em formato hexadecimal
}

export interface User {
  id: string;
  email: string;
  name: string;
}