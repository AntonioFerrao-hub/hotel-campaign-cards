export interface Campaign {
  id: string;
  title: string;
  description: string;
  price: number;
  priceLabel: string;
  image: string;
  startDate: string;
  endDate: string;
  duration: string;
  status: 'active' | 'inactive';
  category: string;
  location: string;
  maxGuests: number;
}

export interface User {
  id: string;
  email: string;
  name: string;
}