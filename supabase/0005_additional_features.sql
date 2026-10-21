-- ============================================================
-- Set El Kol — 0005: Additional Features & Hardened Security
-- Tables: promo_codes, promo_code_usage, support_tickets, 
--         support_messages, app_settings, vendor_analytics_daily, 
--         admin_audit_log
-- Triggers: Role escalation prevention, Audit logging
-- RLS: Complete policies for all new entities
-- ============================================================

-- ------------------------------------------------------------
-- 1. HARDENED SECURITY: PREVENT ROLE ESCALATION
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_unauthorized_role_escalation()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'admin' AND (OLD.role IS NULL OR OLD.role <> 'admin') THEN
    -- Strictly allow only the designated system admin email or existing admin
    IF (auth.jwt() ->> 'email') <> 'setelkol.support@gmail.com' AND NOT public.is_admin() THEN
      RAISE EXCEPTION 'Unauthorized: Ordinary users cannot grant themselves admin privileges';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_prevent_role_escalation ON public.profiles;
CREATE TRIGGER trg_prevent_role_escalation
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  WHEN (NEW.role IS DISTINCT FROM OLD.role)
  EXECUTE FUNCTION public.prevent_unauthorized_role_escalation();

-- ------------------------------------------------------------
-- 2. PROMO CODES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.promo_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('percentage', 'fixed_amount')),
  value NUMERIC(10,2) NOT NULL,
  min_order_amount NUMERIC(10,2) DEFAULT 0,
  max_discount NUMERIC(10,2),
  usage_limit INT,
  usage_count INT DEFAULT 0,
  user_usage_limit INT DEFAULT 1,
  valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  valid_until TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  applicable_vendors UUID[], -- null = all vendors
  applicable_categories UUID[], -- null = all categories
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_promo_codes_code ON public.promo_codes (code);
CREATE INDEX IF NOT EXISTS idx_promo_codes_active ON public.promo_codes (is_active, valid_until);

ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "promo_codes_select_active"
  ON public.promo_codes FOR SELECT
  USING (is_active = true OR public.is_admin());

CREATE POLICY "promo_codes_admin_all"
  ON public.promo_codes FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ------------------------------------------------------------
-- 3. PROMO CODE USAGE TRACKING
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.promo_code_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promo_code_id UUID NOT NULL REFERENCES public.promo_codes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  discount_amount NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_promo_usage_user ON public.promo_code_usage (user_id, promo_code_id);

ALTER TABLE public.promo_code_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "promo_usage_select_own_or_admin"
  ON public.promo_code_usage FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "promo_usage_insert_own"
  ON public.promo_code_usage FOR INSERT
  WITH CHECK (user_id = auth.uid() OR public.is_admin());

-- ------------------------------------------------------------
-- 4. SUPPORT TICKETS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')) DEFAULT 'open',
  priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
  assigned_admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_support_tickets_user ON public.support_tickets (user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets (status);

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "support_tickets_select_own_or_admin"
  ON public.support_tickets FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "support_tickets_insert_own"
  ON public.support_tickets FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "support_tickets_update_own_or_admin"
  ON public.support_tickets FOR UPDATE
  USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());

-- ------------------------------------------------------------
-- 5. SUPPORT MESSAGES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.support_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  is_from_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_support_messages_ticket ON public.support_messages (ticket_id, created_at);

ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "support_messages_select_participant_or_admin"
  ON public.support_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.support_tickets st
      WHERE st.id = support_messages.ticket_id
        AND (st.user_id = auth.uid() OR public.is_admin())
    )
  );

CREATE POLICY "support_messages_insert_participant_or_admin"
  ON public.support_messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND (
      EXISTS (
        SELECT 1 FROM public.support_tickets st
        WHERE st.id = support_messages.ticket_id
          AND (st.user_id = auth.uid() OR public.is_admin())
      )
    )
  );

-- ------------------------------------------------------------
-- 6. APP SETTINGS / FEATURE FLAGS (DYNAMIC ADMIN UPDATES)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "app_settings_select_all"
  ON public.app_settings FOR SELECT
  USING (true);

CREATE POLICY "app_settings_admin_manage"
  ON public.app_settings FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ------------------------------------------------------------
-- 7. VENDOR ANALYTICS DAILY
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.vendor_analytics_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  orders_count INT DEFAULT 0,
  revenue NUMERIC(12,2) DEFAULT 0,
  avg_order_value NUMERIC(10,2) DEFAULT 0,
  new_customers INT DEFAULT 0,
  repeat_customers INT DEFAULT 0,
  cancelled_orders INT DEFAULT 0,
  prep_time_avg_minutes INT,
  UNIQUE(vendor_id, date)
);

CREATE INDEX IF NOT EXISTS idx_vendor_analytics_vendor_date ON public.vendor_analytics_daily (vendor_id, date);

ALTER TABLE public.vendor_analytics_daily ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vendor_analytics_select_owner_or_admin"
  ON public.vendor_analytics_daily FOR SELECT
  USING (vendor_id = auth.uid() OR public.is_admin());

-- ------------------------------------------------------------
-- 8. ADMIN AUDIT LOG
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  old_data JSONB,
  new_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_admin ON public.admin_audit_log (admin_id, created_at);

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_audit_admin_only"
  ON public.admin_audit_log FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());