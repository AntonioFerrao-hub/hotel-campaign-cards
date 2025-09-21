# Documentação de URLs - Sistema de Campanhas de Hotel

## Visão Geral

Este documento descreve o modelo de URLs utilizado para filtrar campanhas no sistema de galeria de campanhas de hotel. As URLs são projetadas para serem utilizadas em iframes e permitem navegação direta e filtros específicos.

## URL Base

```
http://localhost:8080/
```

## Parâmetros Disponíveis

### 1. `category` (string, opcional)
Filtra campanhas por categoria específica.

**Formato:** `?category={nome_da_categoria}`

**Valores Possíveis:**
- `Temporada` - Campanhas sazonais
- `Promocional` - Ofertas especiais  
- `Gastronômico` - Experiências gastronômicas
- `Familiar` - Pacotes para famílias
- `Romântico` - Experiências românticas

**Comportamento:**
- Quando não especificado, mostra todas as categorias
- Valor vazio (`category=`) equivale a "Todas as categorias"
- Case-sensitive (deve corresponder exatamente ao nome da categoria)

### 2. `search` (string, opcional)
Realiza busca textual nos títulos e descrições das campanhas.

**Formato:** `?search={termo_de_busca}`

**Comportamento:**
- Busca case-insensitive
- Procura tanto no título quanto na descrição da campanha
- Suporta termos parciais
- Pode ser combinado com filtro de categoria

## Combinação de Parâmetros

Os parâmetros podem ser combinados usando `&`:

```
?category={categoria}&search={termo}
```

## Exemplos de URLs

### URLs Básicas

#### Todas as campanhas
```
http://localhost:8080/
```

#### Campanhas por categoria específica
```
http://localhost:8080/?category=Temporada
http://localhost:8080/?category=Promocional
http://localhost:8080/?category=Gastronômico
http://localhost:8080/?category=Familiar
http://localhost:8080/?category=Romântico
```

#### Busca textual
```
http://localhost:8080/?search=setembro
http://localhost:8080/?search=resort
http://localhost:8080/?search=praia
```

### URLs Combinadas

#### Categoria + Busca
```
http://localhost:8080/?category=Temporada&search=setembro
http://localhost:8080/?category=Familiar&search=resort
http://localhost:8080/?category=Gastronômico&search=jantar
```

#### Resetar filtros (voltar para todas)
```
http://localhost:8080/?category=
http://localhost:8080/
```

## Implementação em Iframe

### HTML Básico
```html
<iframe 
  src="http://localhost:8080/?category=Temporada" 
  width="100%" 
  height="600"
  frameborder="0">
</iframe>
```

### JavaScript Dinâmico
```javascript
// Função para atualizar iframe com filtros
function updateCampaignIframe(category = '', search = '') {
  const iframe = document.getElementById('campaign-iframe');
  const baseUrl = 'http://localhost:8080/';
  const params = new URLSearchParams();
  
  if (category) params.set('category', category);
  if (search) params.set('search', search);
  
  const url = params.toString() ? `${baseUrl}?${params.toString()}` : baseUrl;
  iframe.src = url;
}

// Exemplos de uso
updateCampaignIframe('Temporada'); // Filtrar por categoria
updateCampaignIframe('', 'resort'); // Buscar por termo
updateCampaignIframe('Familiar', 'praia'); // Combinar filtros
updateCampaignIframe(); // Mostrar todas
```

## Comportamento da Interface

### Sincronização Bidirecional
- URLs são automaticamente atualizadas quando filtros são alterados na interface
- Navegação direta via URL aplica os filtros correspondentes
- Botão "voltar" do navegador funciona corretamente

### Estados da Interface
- **Carregamento:** Exibe indicador de carregamento
- **Resultados encontrados:** Mostra grid de campanhas
- **Nenhum resultado:** Exibe mensagem "Nenhuma campanha encontrada"
- **Filtros ativos:** Badges de categoria ficam destacados

## Codificação de URLs

### Caracteres Especiais
Termos de busca com caracteres especiais devem ser codificados:

```javascript
const searchTerm = "férias & descanso";
const encodedTerm = encodeURIComponent(searchTerm);
// Resultado: f%C3%A9rias%20%26%20descanso
```

### Espaços
Espaços são automaticamente convertidos para `%20` ou `+`:
```
?search=resort+praia
?search=resort%20praia
```

## Limitações e Considerações

### Performance
- Filtros são aplicados em tempo real no frontend
- Não há paginação implementada
- Recomendado para até 1000 campanhas simultâneas

### Compatibilidade
- Funciona em todos os navegadores modernos
- Requer JavaScript habilitado
- Responsivo para dispositivos móveis

### Segurança
- Parâmetros são sanitizados automaticamente
- Não há risco de XSS através dos parâmetros de URL
- Validação de categorias contra lista pré-definida

## Troubleshooting

### Problemas Comuns

#### Categoria não encontrada
```
# Problema: ?category=temporada (minúsculo)
# Solução: ?category=Temporada (primeira letra maiúscula)
```

#### Caracteres especiais na busca
```
# Problema: ?search=férias & spa
# Solução: ?search=f%C3%A9rias%20%26%20spa
```

#### Iframe não carrega
- Verificar se a URL base está correta
- Confirmar que o servidor está rodando na porta 8080
- Verificar políticas de CORS se em domínio diferente

## Versionamento

**Versão:** 1.0  
**Data:** Janeiro 2025  
**Compatibilidade:** React Router v6+

---

*Esta documentação deve ser atualizada sempre que novos parâmetros ou funcionalidades forem adicionados ao sistema.*