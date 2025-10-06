import React, { useState, useRef, useEffect } from 'react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { X, ChevronDown, Search, Check } from 'lucide-react';
import { cn } from '@/lib/utils';

interface MultiSelectOption {
  id: string;
  name: string;
}

interface MultiSelectProps {
  options: MultiSelectOption[];
  selected: MultiSelectOption[];
  onChange: (selected: MultiSelectOption[]) => void;
  placeholder?: string;
  label?: string;
  searchPlaceholder?: string;
  maxHeight?: string;
  className?: string;
}

export const MultiSelect: React.FC<MultiSelectProps> = ({
  options,
  selected,
  onChange,
  placeholder = "Selecione as categorias...",
  label,
  searchPlaceholder = "Buscar categorias...",
  maxHeight = "200px",
  className
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const containerRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Filter options based on search term
  const filteredOptions = options.filter(option =>
    option.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Check if option is selected
  const isSelected = (option: MultiSelectOption) => 
    selected.some(item => item.id === option.id);

  // Toggle option selection
  const toggleOption = (option: MultiSelectOption) => {
    if (isSelected(option)) {
      onChange(selected.filter(item => item.id !== option.id));
    } else {
      onChange([...selected, option]);
    }
  };

  // Remove selected option
  const removeOption = (option: MultiSelectOption) => {
    onChange(selected.filter(item => item.id !== option.id));
  };

  // Clear all selections
  const clearAll = () => {
    onChange([]);
  };

  return (
    <div className={cn("space-y-2", className)}>
      {label && <Label>{label}</Label>}
      
      <div ref={containerRef} className="relative">
        {/* Main trigger button */}
        <Button
          type="button"
          variant="outline"
          onClick={() => setIsOpen(!isOpen)}
          className={cn(
            "w-full justify-between text-left font-normal min-h-[40px] h-auto p-3",
            !selected.length && "text-muted-foreground"
          )}
        >
          <div className="flex flex-wrap gap-1 flex-1">
            {selected.length === 0 ? (
              <span>{placeholder}</span>
            ) : (
              <>
                {selected.slice(0, 2).map((option) => (
                  <Badge
                    key={option.id}
                    variant="secondary"
                    className="bg-teal-100 text-teal-800 hover:bg-teal-200"
                  >
                    {option.name}
                    <X
                      className="h-3 w-3 ml-1 cursor-pointer hover:text-teal-600"
                      onClick={(e) => {
                        e.stopPropagation();
                        removeOption(option);
                      }}
                    />
                  </Badge>
                ))}
                {selected.length > 2 && (
                  <Badge variant="outline" className="bg-gray-100">
                    +{selected.length - 2} mais
                  </Badge>
                )}
              </>
            )}
          </div>
          <div className="flex items-center gap-2">
            {selected.length > 0 && (
              <X
                className="h-4 w-4 text-gray-400 hover:text-gray-600 cursor-pointer"
                onClick={(e) => {
                  e.stopPropagation();
                  clearAll();
                }}
              />
            )}
            <ChevronDown className={cn("h-4 w-4 transition-transform", isOpen && "rotate-180")} />
          </div>
        </Button>

        {/* Dropdown */}
        {isOpen && (
          <div className="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-md shadow-lg">
            {/* Search input */}
            <div className="p-3 border-b">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  ref={inputRef}
                  type="text"
                  placeholder={searchPlaceholder}
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 h-9"
                  autoFocus
                />
              </div>
            </div>

            {/* Options list */}
            <div className="max-h-[200px] overflow-y-auto">
              {filteredOptions.length === 0 ? (
                <div className="p-3 text-sm text-gray-500 text-center">
                  Nenhuma categoria encontrada
                </div>
              ) : (
                filteredOptions.map((option) => (
                  <div
                    key={option.id}
                    className={cn(
                      "flex items-center justify-between p-3 cursor-pointer hover:bg-gray-50 transition-colors",
                      isSelected(option) && "bg-teal-50"
                    )}
                    onClick={() => toggleOption(option)}
                  >
                    <span className={cn(
                      "text-sm",
                      isSelected(option) && "text-teal-700 font-medium"
                    )}>
                      {option.name}
                    </span>
                    {isSelected(option) && (
                      <Check className="h-4 w-4 text-teal-600" />
                    )}
                  </div>
                ))
              )}
            </div>

            {/* Footer with selection count */}
            {selected.length > 0 && (
              <div className="p-3 border-t bg-gray-50 text-xs text-gray-600 flex justify-between items-center">
                <span>{selected.length} categoria{selected.length !== 1 ? 's' : ''} selecionada{selected.length !== 1 ? 's' : ''}</span>
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={clearAll}
                  className="h-6 px-2 text-xs hover:text-red-600"
                >
                  Limpar tudo
                </Button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Selected items display (alternative view) */}
      {selected.length > 0 && (
        <div className="flex flex-wrap gap-2 mt-2">
          {selected.map((option) => (
            <Badge
              key={option.id}
              variant="secondary"
              className="bg-teal-100 text-teal-800 hover:bg-teal-200 cursor-pointer"
            >
              {option.name}
              <X
                className="h-3 w-3 ml-1 hover:text-teal-600"
                onClick={() => removeOption(option)}
              />
            </Badge>
          ))}
        </div>
      )}
    </div>
  );
};