import React, { useState, useEffect } from 'react';
import InputMask from 'react-input-mask';
import { useCampaigns } from '@/contexts/CampaignContext';
import { Campaign } from '@/types/campaign';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { ArrowLeft, Save, Upload, X } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

// Import campaign images
import resortSunset from '@/assets/resort-sunset.jpg';
import beachResort from '@/assets/beach-resort.jpg';
import restaurant from '@/assets/restaurant.jpg';
import familyResort from '@/assets/family-resort.jpg';
interface CampaignFormProps {
  campaign?: Campaign | null;
  onClose: () => void;
}
const availableImages = [{
  url: resortSunset,
  name: 'Resort Sunset'
}, {
  url: beachResort,
  name: 'Beach Resort'
}, {
  url: restaurant,
  name: 'Restaurant'
}, {
  url: familyResort,
  name: 'Family Resort'
}];
export const CampaignForm: React.FC<CampaignFormProps> = ({
  campaign,
  onClose
}) => {
  const {
    addCampaign,
    updateCampaign
  } = useCampaigns();
  const {
    toast
  } = useToast();
  const [isLoading, setIsLoading] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    priceOriginal: '',
    pricePromotional: '',
    priceLabel: 'A partir de',
    image: availableImages[0].url,
    startDate: '',
    endDate: '',
    duration: '',
    status: 'active' as 'active' | 'inactive',
    category: ''
  });
  useEffect(() => {
    if (campaign) {
      setFormData({
        title: campaign.title,
        description: campaign.description,
        priceOriginal: campaign.priceOriginal.toString(),
        pricePromotional: campaign.pricePromotional.toString(),
        priceLabel: campaign.priceLabel,
        image: campaign.image,
        startDate: campaign.startDate,
        endDate: campaign.endDate,
        duration: campaign.duration,
        status: campaign.status,
        category: campaign.category
      });
    }
  }, [campaign]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    const campaignData: Omit<Campaign, 'id'> = {
      title: formData.title,
      description: formData.description,
      priceOriginal: parseFloat(formData.priceOriginal),
      pricePromotional: parseFloat(formData.pricePromotional),
      priceLabel: formData.priceLabel,
      image: formData.image,
      startDate: formData.startDate,
      endDate: formData.endDate,
      duration: formData.duration,
      status: formData.status,
      category: formData.category,
      location: 'São Paulo, SP', // Default location
      maxGuests: 4 // Default max guests
    };

    try {
      if (campaign) {
        await updateCampaign(campaign.id, campaignData);
        toast({
          title: "Campanha atualizada!",
          description: `A campanha "${formData.title}" foi atualizada com sucesso.`
        });
      } else {
        await addCampaign(campaignData);
        toast({
          title: "Campanha criada!",
          description: `A campanha "${formData.title}" foi criada com sucesso.`
        });
      }
      onClose();
    } catch (error) {
      toast({
        title: "Erro",
        description: "Ocorreu um erro ao salvar a campanha.",
        variant: "destructive"
      });
    } finally {
      setIsLoading(false);
    }
  };
  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file type
    if (!file.type.startsWith('image/')) {
      toast({
        title: "Erro",
        description: "Por favor, selecione apenas arquivos de imagem.",
        variant: "destructive"
      });
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      toast({
        title: "Erro",
        description: "A imagem deve ter no máximo 5MB.",
        variant: "destructive"
      });
      return;
    }

    setIsUploading(true);
    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `${Date.now()}.${fileExt}`;
      
      const { data, error } = await supabase.storage
        .from('campaign-images')
        .upload(fileName, file);

      if (error) throw error;

      const { data: { publicUrl } } = supabase.storage
        .from('campaign-images')
        .getPublicUrl(fileName);

      setFormData(prev => ({ ...prev, image: publicUrl }));
      
      toast({
        title: "Sucesso",
        description: "Imagem enviada com sucesso!"
      });
    } catch (error) {
      console.error('Error uploading image:', error);
      toast({
        title: "Erro",
        description: "Erro ao enviar a imagem. Tente novamente.",
        variant: "destructive"
      });
    } finally {
      setIsUploading(false);
    }
  };

  return <div className="min-h-screen bg-background p-4">
      <div className="container mx-auto max-w-2xl">
        <div className="mb-6">
          <Button variant="outline" onClick={onClose} className="gap-2">
            <ArrowLeft className="h-4 w-4" />
            Voltar
          </Button>
        </div>

        <Card className="shadow-[var(--card-shadow)]">
          <CardHeader>
            <CardTitle>
              {campaign ? 'Editar Campanha' : 'Nova Campanha'}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="title">Título da Campanha</Label>
                  <Input id="title" value={formData.title} onChange={e => handleInputChange('title', e.target.value)} placeholder="Ex: Setembro 2025" required />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="category">Categoria</Label>
                  <Select value={formData.category} onValueChange={value => handleInputChange('category', value)}>
                    <SelectTrigger>
                      <SelectValue placeholder="Selecione uma categoria" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Temporada">Temporada</SelectItem>
                      <SelectItem value="Promocional">Promocional</SelectItem>
                      <SelectItem value="Gastronômico">Gastronômico</SelectItem>
                      <SelectItem value="Familiar">Familiar</SelectItem>
                      <SelectItem value="Romântico">Romântico</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="description">Descrição</Label>
                <Textarea id="description" value={formData.description} onChange={e => handleInputChange('description', e.target.value)} placeholder="Ex: Diária para dois adultos" required />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="priceOriginal">Preço Original (R$)</Label>
                  <Input 
                    id="priceOriginal" 
                    type="number"
                    step="0.01"
                    value={formData.priceOriginal}
                    onChange={(e) => handleInputChange('priceOriginal', e.target.value)}
                    placeholder="1950.00" 
                    required 
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="pricePromotional">Preço Promocional (R$)</Label>
                  <Input 
                    id="pricePromotional" 
                    type="number"
                    step="0.01"
                    value={formData.pricePromotional}
                    onChange={(e) => handleInputChange('pricePromotional', e.target.value)}
                    placeholder="1650.00" 
                    required 
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="priceLabel">Rótulo do Preço</Label>
                  <Input id="priceLabel" value={formData.priceLabel} onChange={e => handleInputChange('priceLabel', e.target.value)} placeholder="A partir de" />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="startDate">Data Início</Label>
                  <Input 
                    id="startDate" 
                    type="date"
                    value={formData.startDate}
                    onChange={(e) => handleInputChange('startDate', e.target.value)}
                    required 
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="endDate">Data Fim</Label>
                  <Input 
                    id="endDate" 
                    type="date"
                    value={formData.endDate}
                    onChange={(e) => handleInputChange('endDate', e.target.value)}
                    required 
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="duration">Duração</Label>
                  <Input id="duration" value={formData.duration} onChange={e => handleInputChange('duration', e.target.value)} placeholder="2 diárias" required />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="status">Status</Label>
                  <Select value={formData.status} onValueChange={(value: 'active' | 'inactive') => handleInputChange('status', value)}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="active">Ativa</SelectItem>
                      <SelectItem value="inactive">Inativa</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                
              </div>

              {/* Seletor de imagem e upload */}
              <div className="space-y-4">
                <div className="space-y-2">
                  <Label>Imagem da Campanha</Label>
                  
                  {/* Upload de nova imagem */}
                  <div className="flex gap-2">
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleImageUpload}
                      className="hidden"
                      id="image-upload"
                    />
                    <label
                      htmlFor="image-upload"
                      className="inline-flex items-center gap-2 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground rounded-md cursor-pointer text-sm font-medium transition-colors"
                    >
                      <Upload className="h-4 w-4" />
                      {isUploading ? 'Enviando...' : 'Upload Nova Imagem'}
                    </label>
                  </div>

                  {/* Imagens predefinidas */}
                  <div className="space-y-2">
                    <Label className="text-sm text-muted-foreground">Ou escolha uma imagem predefinida:</Label>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                      {availableImages.map((img) => (
                        <button
                          key={img.url}
                          type="button"
                          onClick={() => setFormData(prev => ({ ...prev, image: img.url }))}
                          className={`relative h-20 rounded-lg overflow-hidden border-2 transition-colors ${
                            formData.image === img.url ? 'border-primary' : 'border-border hover:border-primary/50'
                          }`}
                        >
                          <img src={img.url} alt={img.name} className="w-full h-full object-cover" />
                          {formData.image === img.url && (
                            <div className="absolute inset-0 bg-primary/20 flex items-center justify-center">
                              <div className="bg-primary text-primary-foreground rounded-full p-1">
                                <svg className="h-3 w-3" fill="currentColor" viewBox="0 0 20 20">
                                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                                </svg>
                              </div>
                            </div>
                          )}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Preview da imagem selecionada */}
                <div className="space-y-2">
                  <Label>Preview da Imagem</Label>
                  <div className="w-full h-48 rounded-lg overflow-hidden border">
                    <img src={formData.image} alt="Preview" className="w-full h-full object-cover" />
                  </div>
                </div>
              </div>

              <div className="flex gap-4 pt-4">
                <Button type="submit" disabled={isLoading} className="bg-ocean-primary hover:bg-ocean-dark gap-2 flex-1">
                  <Save className="h-4 w-4" />
                  {isLoading ? 'Salvando...' : campaign ? 'Atualizar' : 'Criar'} Campanha
                </Button>
                <Button type="button" variant="outline" onClick={onClose}>
                  Cancelar
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>;
};