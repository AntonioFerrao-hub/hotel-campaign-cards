import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Badge } from '@/components/ui/badge';
import { Plus, Edit, Trash2, ChevronUp, ChevronDown } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

interface Category {
  id: string;
  name: string;
  description?: string;
  display_order: number;
}

export const CategoryManagement: React.FC = () => {
  const { toast } = useToast();
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [formData, setFormData] = useState({ name: '', description: '' });

  // Generate slug from name
  const generateSlug = (name: string): string => {
    return name
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '') // Remove accents
      .replace(/[^a-z0-9\s-]/g, '') // Remove special characters
      .replace(/\s+/g, '-') // Replace spaces with hyphens
      .replace(/-+/g, '-') // Replace multiple hyphens with single
      .trim()
      .replace(/^-+|-+$/g, ''); // Remove leading/trailing hyphens
  };

  // Fetch categories from Supabase
  const fetchCategories = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('categories')
        .select('*')
        .order('display_order');

      if (error) {
        console.error('Erro ao buscar categorias:', error);
        toast({
          title: "Erro",
          description: "Erro ao carregar categorias.",
          variant: "destructive"
        });
        return;
      }

      setCategories(data || []);
    } catch (error) {
      console.error('Erro inesperado:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const handleCreateCategory = async () => {
    if (!formData.name.trim()) {
      toast({
        title: "Erro",
        description: "Nome da categoria é obrigatório.",
        variant: "destructive"
      });
      return;
    }

    try {
      // Get the next display_order value
      const { data: maxOrderData } = await supabase
        .from('categories')
        .select('display_order')
        .order('display_order', { ascending: false })
        .limit(1);

      const nextOrder = maxOrderData && maxOrderData.length > 0 
        ? maxOrderData[0].display_order + 1 
        : 0;

      const { error } = await supabase
        .from('categories')
        .insert({
          name: formData.name.trim(),
          slug: generateSlug(formData.name.trim()),
          description: formData.description.trim() || null,
          display_order: nextOrder
        });

      if (error) {
        throw error;
      }

      await fetchCategories();
      setFormData({ name: '', description: '' });
      setIsDialogOpen(false);
      
      toast({
        title: "Sucesso",
        description: "Categoria criada com sucesso!"
      });
    } catch (error) {
      console.error('Erro ao criar categoria:', error);
      toast({
        title: "Erro",
        description: "Erro ao criar categoria.",
        variant: "destructive"
      });
    }
  };

  const handleUpdateCategory = async () => {
    if (!formData.name.trim() || !editingCategory) return;

    try {
      const { error } = await supabase
        .from('categories')
        .update({
          name: formData.name.trim(),
          slug: generateSlug(formData.name.trim()),
          description: formData.description.trim() || null
        })
        .eq('id', editingCategory.id);

      if (error) {
        throw error;
      }

      await fetchCategories();
      setEditingCategory(null);
      setFormData({ name: '', description: '' });
      setIsDialogOpen(false);
      
      toast({
        title: "Sucesso",
        description: "Categoria atualizada com sucesso!"
      });
    } catch (error) {
      console.error('Erro ao atualizar categoria:', error);
      toast({
        title: "Erro",
        description: "Erro ao atualizar categoria.",
        variant: "destructive"
      });
    }
  };

  const handleDeleteCategory = async (categoryId: string) => {
    try {
      const { error } = await supabase
        .from('categories')
        .delete()
        .eq('id', categoryId);

      if (error) {
        throw error;
      }

      await fetchCategories();
      
      toast({
        title: "Sucesso",
        description: "Categoria excluída com sucesso!"
      });
    } catch (error) {
      console.error('Erro ao excluir categoria:', error);
      toast({
        title: "Erro",
        description: "Erro ao excluir categoria.",
        variant: "destructive"
      });
    }
  };

  const handleMoveUp = async (category: Category) => {
    const currentIndex = categories.findIndex(c => c.id === category.id);
    if (currentIndex <= 0) return;

    const previousCategory = categories[currentIndex - 1];
    
    try {
      // Swap display_order values
      await supabase
        .from('categories')
        .update({ display_order: previousCategory.display_order })
        .eq('id', category.id);

      await supabase
        .from('categories')
        .update({ display_order: category.display_order })
        .eq('id', previousCategory.id);

      await fetchCategories();
      
      toast({
        title: "Sucesso",
        description: "Categoria movida para cima!"
      });
    } catch (error) {
      console.error('Erro ao mover categoria:', error);
      toast({
        title: "Erro",
        description: "Erro ao mover categoria.",
        variant: "destructive"
      });
    }
  };

  const handleMoveDown = async (category: Category) => {
    const currentIndex = categories.findIndex(c => c.id === category.id);
    if (currentIndex >= categories.length - 1) return;

    const nextCategory = categories[currentIndex + 1];
    
    try {
      // Swap display_order values
      await supabase
        .from('categories')
        .update({ display_order: nextCategory.display_order })
        .eq('id', category.id);

      await supabase
        .from('categories')
        .update({ display_order: category.display_order })
        .eq('id', nextCategory.id);

      await fetchCategories();
      
      toast({
        title: "Sucesso",
        description: "Categoria movida para baixo!"
      });
    } catch (error) {
      console.error('Erro ao mover categoria:', error);
      toast({
        title: "Erro",
        description: "Erro ao mover categoria.",
        variant: "destructive"
      });
    }
  };

  const openEditDialog = (category: Category) => {
    setEditingCategory(category);
    setFormData({ name: category.name, description: category.description || '' });
    setIsDialogOpen(true);
  };

  const openCreateDialog = () => {
    setEditingCategory(null);
    setFormData({ name: '', description: '' });
    setIsDialogOpen(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Gerenciar Categorias</h2>
        
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={openCreateDialog} className="gap-2">
              <Plus className="h-4 w-4" />
              Nova Categoria
            </Button>
          </DialogTrigger>
          
          <DialogContent>
            <DialogHeader>
              <DialogTitle>
                {editingCategory ? 'Editar Categoria' : 'Nova Categoria'}
              </DialogTitle>
            </DialogHeader>
            
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="name">Nome da Categoria</Label>
                <Input 
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="Ex: Romântico"
                />
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="description">Descrição (opcional)</Label>
                <Input 
                  id="description"
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Ex: Experiências românticas para casais"
                />
              </div>
              
              <div className="flex gap-2 pt-4">
                <Button 
                  onClick={editingCategory ? handleUpdateCategory : handleCreateCategory}
                  className="flex-1"
                >
                  {editingCategory ? 'Atualizar' : 'Criar'}
                </Button>
                <Button 
                  variant="outline" 
                  onClick={() => setIsDialogOpen(false)}
                >
                  Cancelar
                </Button>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {loading ? (
        <div className="text-center py-8">
          <p className="text-muted-foreground">Carregando categorias...</p>
        </div>
      ) : categories.length === 0 ? (
        <div className="text-center py-8">
          <p className="text-muted-foreground">Nenhuma categoria encontrada.</p>
        </div>
      ) : (
        categories.map((category) => (
          <Card key={category.id}>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Badge variant="secondary">{category.name}</Badge>
                  {category.description && (
                    <span className="text-sm text-muted-foreground">
                      {category.description}
                    </span>
                  )}
                </div>
                
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleMoveUp(category)}
                    disabled={categories.findIndex(c => c.id === category.id) === 0}
                    title="Mover para cima"
                  >
                    <ChevronUp className="h-4 w-4" />
                  </Button>
                  
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleMoveDown(category)}
                    disabled={categories.findIndex(c => c.id === category.id) === categories.length - 1}
                    title="Mover para baixo"
                  >
                    <ChevronDown className="h-4 w-4" />
                  </Button>
                  
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => openEditDialog(category)}
                    title="Editar categoria"
                  >
                    <Edit className="h-4 w-4" />
                  </Button>
                  
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button variant="outline" size="sm" title="Excluir categoria">
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
                        <AlertDialogDescription>
                          Tem certeza que deseja excluir a categoria "{category.name}"? 
                          Esta ação não pode ser desfeita.
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                        <AlertDialogAction 
                          onClick={() => handleDeleteCategory(category.id)}
                          className="bg-destructive hover:bg-destructive/90"
                        >
                          Excluir
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
                </div>
              </div>
            </CardContent>
          </Card>
        ))
      )}
    </div>
  );
};