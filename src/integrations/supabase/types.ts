export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "12.2.3 (519615d)"
  }
  public: {
    Tables: {
      campaigns: {
        Row: {
          created_at: string
          description: string | null
          end_date: string | null
          hotel_id: string
          id: string
          is_active: boolean | null
          price_original: number | null
          price_promotional: number | null
          start_date: string | null
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          end_date?: string | null
          hotel_id: string
          id?: string
          is_active?: boolean | null
          price_original?: number | null
          price_promotional?: number | null
          start_date?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          end_date?: string | null
          hotel_id?: string
          id?: string
          is_active?: boolean | null
          price_original?: number | null
          price_promotional?: number | null
          start_date?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "campaigns_hotel_id_fkey"
            columns: ["hotel_id"]
            isOneToOne: false
            referencedRelation: "hotels"
            referencedColumns: ["id"]
          },
        ]
      }
      hotel_module_items: {
        Row: {
          button_text: string | null
          button_url: string | null
          created_at: string
          custom_data: Json | null
          description: string | null
          features: Json | null
          icon: string | null
          id: string
          image_url: string | null
          is_active: boolean
          item_order: number
          item_type: string
          module_id: string
          price: number | null
          price_unit: string | null
          subtitle: string | null
          title: string
          updated_at: string
        }
        Insert: {
          button_text?: string | null
          button_url?: string | null
          created_at?: string
          custom_data?: Json | null
          description?: string | null
          features?: Json | null
          icon?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          item_order?: number
          item_type: string
          module_id: string
          price?: number | null
          price_unit?: string | null
          subtitle?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          button_text?: string | null
          button_url?: string | null
          created_at?: string
          custom_data?: Json | null
          description?: string | null
          features?: Json | null
          icon?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          item_order?: number
          item_type?: string
          module_id?: string
          price?: number | null
          price_unit?: string | null
          subtitle?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_hotel_module_items_module_id"
            columns: ["module_id"]
            isOneToOne: false
            referencedRelation: "hotel_modules"
            referencedColumns: ["id"]
          },
        ]
      }
      hotel_modules: {
        Row: {
          background_color: string | null
          background_image: string | null
          button_text: string | null
          button_url: string | null
          created_at: string
          custom_data: Json | null
          description: string | null
          hotel_id: string
          id: string
          is_active: boolean
          module_order: number
          module_type: string
          subtitle: string | null
          text_color: string | null
          title: string | null
          updated_at: string
        }
        Insert: {
          background_color?: string | null
          background_image?: string | null
          button_text?: string | null
          button_url?: string | null
          created_at?: string
          custom_data?: Json | null
          description?: string | null
          hotel_id: string
          id?: string
          is_active?: boolean
          module_order?: number
          module_type: string
          subtitle?: string | null
          text_color?: string | null
          title?: string | null
          updated_at?: string
        }
        Update: {
          background_color?: string | null
          background_image?: string | null
          button_text?: string | null
          button_url?: string | null
          created_at?: string
          custom_data?: Json | null
          description?: string | null
          hotel_id?: string
          id?: string
          is_active?: boolean
          module_order?: number
          module_type?: string
          subtitle?: string | null
          text_color?: string | null
          title?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_hotel_modules_hotel_id"
            columns: ["hotel_id"]
            isOneToOne: false
            referencedRelation: "hotels"
            referencedColumns: ["id"]
          },
        ]
      }
      hotels: {
        Row: {
          created_at: string
          description: string | null
          email: string | null
          footer_scripts: string | null
          header_color: string | null
          header_scripts: string | null
          id: string
          is_active: boolean | null
          location: string | null
          name: string
          phone: string | null
          slug: string
          subdomain: string
          updated_at: string
          website: string | null
          whatsapp: string | null
        }
        Insert: {
          created_at?: string
          description?: string | null
          email?: string | null
          footer_scripts?: string | null
          header_color?: string | null
          header_scripts?: string | null
          id?: string
          is_active?: boolean | null
          location?: string | null
          name: string
          phone?: string | null
          slug: string
          subdomain: string
          updated_at?: string
          website?: string | null
          whatsapp?: string | null
        }
        Update: {
          created_at?: string
          description?: string | null
          email?: string | null
          footer_scripts?: string | null
          header_color?: string | null
          header_scripts?: string | null
          id?: string
          is_active?: boolean | null
          location?: string | null
          name?: string
          phone?: string | null
          slug?: string
          subdomain?: string
          updated_at?: string
          website?: string | null
          whatsapp?: string | null
        }
        Relationships: []
      }
      profiles: {
        Row: {
          created_at: string
          email: string
          hotel_ids: string[] | null
          id: string
          name: string
          password_hash: string | null
          role: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          email: string
          hotel_ids?: string[] | null
          id: string
          name: string
          password_hash?: string | null
          role?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          email?: string
          hotel_ids?: string[] | null
          id?: string
          name?: string
          password_hash?: string | null
          role?: string
          updated_at?: string
        }
        Relationships: []
      }
      subpages: {
        Row: {
          created_at: string
          custom_description: string | null
          custom_hero_image: string | null
          custom_subtitle: string | null
          custom_title: string | null
          hotel_id: string
          id: string
          is_active: boolean | null
          name: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          custom_description?: string | null
          custom_hero_image?: string | null
          custom_subtitle?: string | null
          custom_title?: string | null
          hotel_id: string
          id?: string
          is_active?: boolean | null
          name: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          custom_description?: string | null
          custom_hero_image?: string | null
          custom_subtitle?: string | null
          custom_title?: string | null
          hotel_id?: string
          id?: string
          is_active?: boolean | null
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "subpages_hotel_id_fkey"
            columns: ["hotel_id"]
            isOneToOne: false
            referencedRelation: "hotels"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      create_user_profile: {
        Args: {
          user_email: string
          user_hotel_ids?: string[]
          user_name: string
          user_role?: string
        }
        Returns: string
      }
      create_user_with_password: {
        Args: {
          user_email: string
          user_hotel_ids?: string[]
          user_name: string
          user_password: string
          user_role?: string
        }
        Returns: string
      }
      delete_user_profile: {
        Args: { target_user_id: string }
        Returns: boolean
      }
      get_all_public_hotels: {
        Args: Record<PropertyKey, never>
        Returns: {
          description: string
          id: string
          is_active: boolean
          location: string
          name: string
          slug: string
          subdomain: string
        }[]
      }
      get_current_user_role: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      get_hotel_contact_info: {
        Args: { hotel_id: string }
        Returns: {
          email: string
          phone: string
          website: string
          whatsapp: string
        }[]
      }
      get_public_hotel_info: {
        Args: { hotel_slug: string }
        Returns: {
          description: string
          id: string
          is_active: boolean
          location: string
          name: string
          slug: string
          subdomain: string
        }[]
      }
      reset_user_password: {
        Args: { new_password: string; user_email: string }
        Returns: boolean
      }
      update_user_profile: {
        Args: {
          target_user_id: string
          user_email: string
          user_hotel_ids: string[]
          user_name: string
          user_role: string
        }
        Returns: boolean
      }
      verify_user_password: {
        Args: { user_email: string; user_password: string }
        Returns: {
          user_data: Json
        }[]
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
