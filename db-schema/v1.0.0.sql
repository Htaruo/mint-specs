-- mint MVP database snapshot v1.0.0
-- Supabase PostgreSQL / public schema
-- Compatible with offline-first sync: server id is local indexing only.
-- Relationships use *_uuid columns; physical REFERENCES are intentionally avoided.

BEGIN;

CREATE TABLE IF NOT EXISTS public.schema_metadata (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  key text NOT NULL,
  value text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT schema_metadata_key_live UNIQUE (key)
);

INSERT INTO public.schema_metadata (key, value)
VALUES ('db_snapshot', 'v1.0.0')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now();

CREATE TABLE IF NOT EXISTS public.account (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  email text,
  display_name text,
  role text NOT NULL DEFAULT 'tenant',
  status text NOT NULL DEFAULT 'active',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT account_role_check CHECK (role IN ('system_admin','owner','caretaker','tenant')),
  CONSTRAINT account_status_check CHECK (status IN ('active','disabled','pending'))
);

CREATE TABLE IF NOT EXISTS public.property (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  owner_account_uuid uuid NOT NULL,
  name text NOT NULL,
  address text,
  billing_day smallint NOT NULL DEFAULT 1,
  due_day smallint NOT NULL DEFAULT 5,
  currency char(3) NOT NULL DEFAULT 'PHP',
  inquiry_enabled boolean NOT NULL DEFAULT false,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT property_billing_day_check CHECK (billing_day BETWEEN 1 AND 28),
  CONSTRAINT property_due_day_check CHECK (due_day BETWEEN 1 AND 28),
  CONSTRAINT property_currency_check CHECK (currency = 'PHP')
);

CREATE TABLE IF NOT EXISTS public.property_member (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  account_uuid uuid NOT NULL,
  role text NOT NULL,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT property_member_role_check CHECK (role IN ('owner','caretaker'))
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_property_member_live
  ON public.property_member (property_uuid, account_uuid, role)
  WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_property_member_property ON public.property_member (property_uuid);
CREATE INDEX IF NOT EXISTS idx_property_member_account ON public.property_member (account_uuid);

CREATE TABLE IF NOT EXISTS public.room (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  name text NOT NULL,
  room_type text NOT NULL DEFAULT 'room',
  monthly_rent numeric(14,2) NOT NULL DEFAULT 0,
  bed_capacity integer NOT NULL DEFAULT 1,
  occupied_count integer NOT NULL DEFAULT 0,
  public_visible boolean NOT NULL DEFAULT false,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT room_rent_check CHECK (monthly_rent >= 0),
  CONSTRAINT room_capacity_check CHECK (bed_capacity >= 1),
  CONSTRAINT room_occupied_check CHECK (occupied_count BETWEEN 0 AND bed_capacity)
);

CREATE INDEX IF NOT EXISTS idx_room_property ON public.room (property_uuid);

CREATE TABLE IF NOT EXISTS public.tenancy (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  room_uuid uuid NOT NULL,
  tenant_account_uuid uuid NOT NULL,
  starts_on date,
  ends_on date,
  monthly_rent numeric(14,2),
  status text NOT NULL DEFAULT 'active',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT tenancy_status_check CHECK (status IN ('pending','active','ended')),
  CONSTRAINT tenancy_dates_check CHECK (ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on),
  CONSTRAINT tenancy_rent_check CHECK (monthly_rent IS NULL OR monthly_rent >= 0)
);

CREATE INDEX IF NOT EXISTS idx_tenancy_property ON public.tenancy (property_uuid);
CREATE INDEX IF NOT EXISTS idx_tenancy_room ON public.tenancy (room_uuid);
CREATE INDEX IF NOT EXISTS idx_tenancy_tenant ON public.tenancy (tenant_account_uuid);
CREATE UNIQUE INDEX IF NOT EXISTS idx_tenancy_live
  ON public.tenancy (tenant_account_uuid, room_uuid)
  WHERE archived_at IS NULL AND status = 'active';

CREATE TABLE IF NOT EXISTS public.utility_meter (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  room_uuid uuid,
  utility_type text NOT NULL,
  name text NOT NULL,
  unit text NOT NULL,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT utility_meter_type_check CHECK (utility_type IN ('electricity','water')),
  CONSTRAINT utility_meter_unit_check CHECK (unit IN ('kWh','m3'))
);

CREATE INDEX IF NOT EXISTS idx_meter_property ON public.utility_meter (property_uuid);
CREATE INDEX IF NOT EXISTS idx_meter_room ON public.utility_meter (room_uuid);

CREATE TABLE IF NOT EXISTS public.utility_rate (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  utility_type text NOT NULL,
  method text NOT NULL,
  rate numeric(14,4),
  shared_amount numeric(14,2),
  allocation_count integer,
  effective_from date NOT NULL,
  effective_to date,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT utility_rate_type_check CHECK (utility_type IN ('electricity','water')),
  CONSTRAINT utility_rate_method_check CHECK (method IN ('submeter','shared')),
  CONSTRAINT utility_rate_submeter_check
    CHECK (method <> 'submeter' OR (rate IS NOT NULL AND rate >= 0)),
  CONSTRAINT utility_rate_shared_check
    CHECK (method <> 'shared' OR
      (shared_amount IS NOT NULL AND shared_amount >= 0 AND allocation_count IS NOT NULL AND allocation_count > 0)),
  CONSTRAINT utility_rate_dates_check CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE INDEX IF NOT EXISTS idx_utility_rate_property ON public.utility_rate (property_uuid);

CREATE TABLE IF NOT EXISTS public.meter_reading (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  meter_uuid uuid NOT NULL,
  recorded_by_account_uuid uuid,
  reading decimal(18,4) NOT NULL,
  previous_reading decimal(18,4),
  reading_at timestamptz NOT NULL,
  note text,
  photo_path text,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT meter_reading_nonnegative_check CHECK (reading >= 0),
  CONSTRAINT meter_reading_delta_check
    CHECK (previous_reading IS NULL OR reading >= previous_reading)
);

CREATE INDEX IF NOT EXISTS idx_meter_reading_property ON public.meter_reading (property_uuid);
CREATE INDEX IF NOT EXISTS idx_meter_reading_meter ON public.meter_reading (meter_uuid);

CREATE TABLE IF NOT EXISTS public.billing_period (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  period_month date NOT NULL,
  status text NOT NULL DEFAULT 'open',
  closes_at timestamptz,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT billing_period_status_check CHECK (status IN ('open','closed')),
  CONSTRAINT billing_period_month_check CHECK (extract(day from period_month) = 1)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_billing_period_live
  ON public.billing_period (property_uuid, period_month)
  WHERE archived_at IS NULL;

CREATE TABLE IF NOT EXISTS public.bill (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  billing_period_uuid uuid NOT NULL,
  room_uuid uuid,
  tenancy_uuid uuid NOT NULL,
  tenant_account_uuid uuid NOT NULL,
  due_at timestamptz,
  rent_amount numeric(14,2) NOT NULL DEFAULT 0,
  utility_amount numeric(14,2) NOT NULL DEFAULT 0,
  previous_balance numeric(14,2) NOT NULL DEFAULT 0,
  adjustment_amount numeric(14,2) NOT NULL DEFAULT 0,
  total_amount numeric(14,2) NOT NULL DEFAULT 0,
  currency char(3) NOT NULL DEFAULT 'PHP',
  status text NOT NULL DEFAULT 'draft',
  published_at timestamptz,
  published_by_account_uuid uuid,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT bill_status_check
    CHECK (status IN ('draft','published','adjusted','void')),
  CONSTRAINT bill_currency_check CHECK (currency = 'PHP'),
  CONSTRAINT bill_amounts_check
    CHECK (rent_amount >= 0 AND utility_amount >= 0 AND
           adjustment_amount >= 0 AND total_amount >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_bill_live_tenancy_period
  ON public.bill (billing_period_uuid, tenancy_uuid)
  WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_bill_property ON public.bill (property_uuid);
CREATE INDEX IF NOT EXISTS idx_bill_tenant ON public.bill (tenant_account_uuid);
CREATE INDEX IF NOT EXISTS idx_bill_period ON public.bill (billing_period_uuid);

CREATE TABLE IF NOT EXISTS public.bill_item (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  bill_uuid uuid NOT NULL,
  property_uuid uuid NOT NULL,
  item_type text NOT NULL,
  description text NOT NULL,
  quantity decimal(18,4) NOT NULL DEFAULT 1,
  unit_rate numeric(14,4),
  amount numeric(14,2) NOT NULL,
  meter_uuid uuid,
  meter_reading_uuid uuid,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT bill_item_type_check
    CHECK (item_type IN ('rent','electricity','water','other','adjustment')),
  CONSTRAINT bill_item_amount_check CHECK (amount >= 0)
);

CREATE INDEX IF NOT EXISTS idx_bill_item_bill ON public.bill_item (bill_uuid);
CREATE INDEX IF NOT EXISTS idx_bill_item_property ON public.bill_item (property_uuid);

CREATE TABLE IF NOT EXISTS public.bill_adjustment (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  bill_uuid uuid NOT NULL,
  property_uuid uuid NOT NULL,
  adjustment_type text NOT NULL,
  amount numeric(14,2) NOT NULL,
  reason text NOT NULL,
  approved_by_account_uuid uuid,
  approved_at timestamptz,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT bill_adjustment_type_check
    CHECK (adjustment_type IN ('credit','charge','correction','waiver'))
);

CREATE INDEX IF NOT EXISTS idx_bill_adjustment_bill ON public.bill_adjustment (bill_uuid);

CREATE TABLE IF NOT EXISTS public.payment_submission (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  bill_uuid uuid NOT NULL,
  tenant_account_uuid uuid NOT NULL,
  amount numeric(14,2) NOT NULL,
  payment_date date NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  submitted_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT payment_submission_amount_check CHECK (amount > 0),
  CONSTRAINT payment_submission_status_check
    CHECK (status IN ('pending','approved','rejected'))
);

CREATE INDEX IF NOT EXISTS idx_payment_submission_bill ON public.payment_submission (bill_uuid);
CREATE INDEX IF NOT EXISTS idx_payment_submission_property ON public.payment_submission (property_uuid);
CREATE INDEX IF NOT EXISTS idx_payment_submission_tenant ON public.payment_submission (tenant_account_uuid);

CREATE TABLE IF NOT EXISTS public.payment_receipt (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  submission_uuid uuid NOT NULL,
  bill_uuid uuid NOT NULL,
  tenant_account_uuid uuid NOT NULL,
  storage_path text NOT NULL,
  file_name text,
  mime_type text,
  file_size bigint,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT payment_receipt_size_check CHECK (file_size IS NULL OR file_size >= 0)
);

CREATE INDEX IF NOT EXISTS idx_payment_receipt_submission ON public.payment_receipt (submission_uuid);
CREATE INDEX IF NOT EXISTS idx_payment_receipt_bill ON public.payment_receipt (bill_uuid);

CREATE TABLE IF NOT EXISTS public.payment_verification (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  submission_uuid uuid NOT NULL,
  bill_uuid uuid NOT NULL,
  property_uuid uuid NOT NULL,
  decision text NOT NULL,
  reason text,
  verified_by_account_uuid uuid,
  receipt_reference text,
  verified_at timestamptz,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT payment_verification_decision_check
    CHECK (decision IN ('approved','rejected'))
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_verification_live_submission
  ON public.payment_verification (submission_uuid)
  WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_payment_verification_bill ON public.payment_verification (bill_uuid);

CREATE TABLE IF NOT EXISTS public.notification (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  account_uuid uuid NOT NULL,
  property_uuid uuid,
  notification_type text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  channel text NOT NULL,
  status text NOT NULL DEFAULT 'queued',
  delivered_at timestamptz,
  read_at timestamptz,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT notification_channel_check CHECK (channel IN ('in_app','email')),
  CONSTRAINT notification_status_check
    CHECK (status IN ('queued','sent','delivered','failed','read'))
);

CREATE INDEX IF NOT EXISTS idx_notification_account ON public.notification (account_uuid);
CREATE INDEX IF NOT EXISTS idx_notification_property ON public.notification (property_uuid);

CREATE TABLE IF NOT EXISTS public.public_availability (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  room_uuid uuid,
  title text,
  general_rate numeric(14,2),
  available_count integer NOT NULL DEFAULT 0,
  description text,
  published boolean NOT NULL DEFAULT false,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT public_availability_count_check CHECK (available_count >= 0),
  CONSTRAINT public_availability_rate_check CHECK (general_rate IS NULL OR general_rate >= 0)
);

CREATE INDEX IF NOT EXISTS idx_public_availability_property ON public.public_availability (property_uuid);

CREATE TABLE IF NOT EXISTS public.property_inquiry (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  property_uuid uuid NOT NULL,
  room_uuid uuid,
  name text,
  contact text,
  message text,
  status text NOT NULL DEFAULT 'new',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT property_inquiry_status_check
    CHECK (status IN ('new','contacted','closed'))
);

CREATE INDEX IF NOT EXISTS idx_property_inquiry_property ON public.property_inquiry (property_uuid);

CREATE TABLE IF NOT EXISTS public.privacy_request (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  account_uuid uuid NOT NULL,
  request_type text NOT NULL,
  details text,
  status text NOT NULL DEFAULT 'received',
  resolution text,
  resolved_at timestamptz,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CONSTRAINT privacy_request_type_check
    CHECK (request_type IN ('access','correction','deletion','restriction','help')),
  CONSTRAINT privacy_request_status_check
    CHECK (status IN ('received','reviewing','resolved','rejected'))
);

CREATE INDEX IF NOT EXISTS idx_privacy_request_account ON public.privacy_request (account_uuid);

CREATE TABLE IF NOT EXISTS public.audit_event (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  actor_account_uuid uuid,
  entity_type text NOT NULL,
  entity_uuid uuid,
  property_uuid uuid,
  action text NOT NULL,
  reason text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_audit_event_entity ON public.audit_event (entity_type, entity_uuid);
CREATE INDEX IF NOT EXISTS idx_audit_event_property ON public.audit_event (property_uuid);
CREATE INDEX IF NOT EXISTS idx_audit_event_actor ON public.audit_event (actor_account_uuid);

-- Authentication profile creation
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.account (uuid, email, role, status, created_at, updated_at)
  VALUES (NEW.id, NEW.email, 'tenant', 'active', now(), now())
  ON CONFLICT (uuid) DO UPDATE
    SET email = EXCLUDED.email,
        updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- Stamps the server actor when a sync/API row is inserted.
CREATE OR REPLACE FUNCTION public.stamp_created_by()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.created_by IS NULL AND auth.uid() IS NOT NULL THEN
    NEW.created_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

-- Install created-by stamping consistently on every offline-sync table.
DO $do$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'account','property','property_member','room','tenancy','utility_meter',
    'utility_rate','meter_reading','billing_period','bill','bill_item',
    'bill_adjustment','payment_submission','payment_receipt',
    'payment_verification','notification','public_availability',
    'property_inquiry','privacy_request','audit_event'
  ] LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS stamp_created_by ON public.%I',
      t
    );
    EXECUTE format(
      'CREATE TRIGGER stamp_created_by BEFORE INSERT ON public.%I
       FOR EACH ROW EXECUTE FUNCTION public.stamp_created_by()',
      t
    );
  END LOOP;
END;
$do$;

-- Account role/status changes are privileged operations.
CREATE OR REPLACE FUNCTION public.protect_account_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_system_admin() THEN
    NEW.role := OLD.role;
    NEW.status := OLD.status;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_account_fields ON public.account;
CREATE TRIGGER protect_account_fields
BEFORE UPDATE ON public.account
FOR EACH ROW EXECUTE FUNCTION public.protect_account_fields();

-- Audit events are append-only.
CREATE OR REPLACE FUNCTION public.prevent_audit_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION 'audit_event rows are append-only';
END;
$$;

DROP TRIGGER IF EXISTS prevent_audit_update ON public.audit_event;
CREATE TRIGGER prevent_audit_update
BEFORE UPDATE OR DELETE ON public.audit_event
FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_mutation();

-- Published bills cannot have their original financial snapshot overwritten.
CREATE OR REPLACE FUNCTION public.prevent_published_bill_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.published_at IS NOT NULL
     AND (NEW.rent_amount IS DISTINCT FROM OLD.rent_amount
       OR NEW.utility_amount IS DISTINCT FROM OLD.utility_amount
       OR NEW.previous_balance IS DISTINCT FROM OLD.previous_balance
       OR NEW.adjustment_amount IS DISTINCT FROM OLD.adjustment_amount
       OR NEW.total_amount IS DISTINCT FROM OLD.total_amount
       OR NEW.due_at IS DISTINCT FROM OLD.due_at
       OR NEW.currency IS DISTINCT FROM OLD.currency) THEN
    RAISE EXCEPTION 'published bill financial data is immutable';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_published_bill_mutation ON public.bill;
CREATE TRIGGER prevent_published_bill_mutation
BEFORE UPDATE ON public.bill
FOR EACH ROW EXECUTE FUNCTION public.prevent_published_bill_mutation();

-- RLS helper functions
CREATE OR REPLACE FUNCTION public.is_system_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.account
    WHERE uuid = auth.uid()
      AND role = 'system_admin'
      AND status = 'active'
      AND archived_at IS NULL
  );
$$;

CREATE OR REPLACE FUNCTION public.is_property_member(p_property_uuid uuid, p_roles text[] DEFAULT NULL)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.is_system_admin()
     OR EXISTS (
       SELECT 1
       FROM public.property_member pm
       WHERE pm.property_uuid = p_property_uuid
         AND pm.account_uuid = auth.uid()
         AND pm.archived_at IS NULL
         AND (p_roles IS NULL OR pm.role = ANY(p_roles))
     );
$$;

CREATE OR REPLACE FUNCTION public.is_property_tenant(p_property_uuid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.is_system_admin()
     OR EXISTS (
       SELECT 1
       FROM public.tenancy t
       WHERE t.property_uuid = p_property_uuid
         AND t.tenant_account_uuid = auth.uid()
         AND t.status = 'active'
         AND t.archived_at IS NULL
     );
$$;

ALTER TABLE public.account ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schema_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_member ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenancy ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.utility_meter ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.utility_rate ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meter_reading ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_period ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bill ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bill_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bill_adjustment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_submission ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_receipt ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_verification ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.public_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_inquiry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.privacy_request ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_event ENABLE ROW LEVEL SECURITY;

-- Account and property scope
DROP POLICY IF EXISTS account_select_own_or_admin ON public.account;
CREATE POLICY account_select_own_or_admin ON public.account
FOR SELECT USING (uuid = auth.uid() OR public.is_system_admin());
DROP POLICY IF EXISTS account_update_own ON public.account;
CREATE POLICY account_update_own ON public.account
FOR UPDATE USING (uuid = auth.uid() OR public.is_system_admin())
WITH CHECK (uuid = auth.uid() OR public.is_system_admin());

DROP POLICY IF EXISTS property_select_member ON public.property;
CREATE POLICY property_select_member ON public.property
FOR SELECT USING (owner_account_uuid = auth.uid()
  OR public.is_property_member(uuid)
  OR public.is_property_tenant(uuid));
DROP POLICY IF EXISTS property_owner_write ON public.property;
CREATE POLICY property_owner_write ON public.property
FOR ALL USING (owner_account_uuid = auth.uid() OR public.is_system_admin())
WITH CHECK (owner_account_uuid = auth.uid() OR public.is_system_admin());

DROP POLICY IF EXISTS member_read ON public.property_member;
CREATE POLICY member_read ON public.property_member
FOR SELECT USING (account_uuid = auth.uid()
  OR public.is_property_member(property_uuid));
DROP POLICY IF EXISTS member_owner_write ON public.property_member;
CREATE POLICY member_owner_write ON public.property_member
FOR ALL USING (public.is_property_member(property_uuid, ARRAY['owner'])
  OR public.is_system_admin())
WITH CHECK (public.is_property_member(property_uuid, ARRAY['owner'])
  OR public.is_system_admin());

-- Property data
DROP POLICY IF EXISTS room_scope ON public.room;
CREATE POLICY room_scope ON public.room
FOR SELECT USING (public.is_property_member(property_uuid)
  OR public.is_property_tenant(property_uuid));
DROP POLICY IF EXISTS room_owner_write ON public.room;
CREATE POLICY room_owner_write ON public.room
FOR ALL USING (public.is_property_member(property_uuid, ARRAY['owner'])
  OR public.is_system_admin())
WITH CHECK (public.is_property_member(property_uuid, ARRAY['owner'])
  OR public.is_system_admin());

DROP POLICY IF EXISTS tenancy_scope ON public.tenancy;
CREATE POLICY tenancy_scope ON public.tenancy
FOR SELECT USING (tenant_account_uuid = auth.uid()
  OR public.is_property_member(property_uuid));
DROP POLICY IF EXISTS tenancy_owner_write ON public.tenancy;
CREATE POLICY tenancy_owner_write ON public.tenancy
FOR ALL USING (public.is_property_member(property_uuid, ARRAY['owner'])
  OR public.is_system_admin())
WITH CHECK (public.is_property_member(property_uuid, ARRAY['owner'])
  OR public.is_system_admin());

-- Meters and utility configuration
DROP POLICY IF EXISTS meter_scope ON public.utility_meter;
CREATE POLICY meter_scope ON public.utility_meter
FOR SELECT USING (public.is_property_member(property_uuid));
DROP POLICY IF EXISTS meter_caretaker_write ON public.utility_meter;
CREATE POLICY meter_caretaker_write ON public.utility_meter
FOR ALL USING (public.is_property_member(property_uuid))
WITH CHECK (public.is_property_member(property_uuid));

DROP POLICY IF EXISTS meter_rate_scope ON public.utility_rate;
CREATE POLICY meter_rate_scope ON public.utility_rate
FOR SELECT USING (public.is_property_member(property_uuid));
DROP POLICY IF EXISTS meter_rate_owner_write ON public.utility_rate;
CREATE POLICY meter_rate_owner_write ON public.utility_rate
FOR ALL USING (public.is_property_member(property_uuid, ARRAY['owner'])
  OR public.is_system_admin())
WITH CHECK (public.is_property_member(property_uuid, ARRAY['owner'])
  OR public.is_system_admin());

DROP POLICY IF EXISTS meter_reading_scope ON public.meter_reading;
CREATE POLICY meter_reading_scope ON public.meter_reading
FOR SELECT USING (public.is_property_member(property_uuid));
DROP POLICY IF EXISTS meter_reading_write ON public.meter_reading;
CREATE POLICY meter_reading_write ON public.meter_reading
FOR ALL USING (public.is_property_member(property_uuid))
WITH CHECK (public.is_property_member(property_uuid));

-- Billing
DROP POLICY IF EXISTS billing_period_scope ON public.billing_period;
CREATE POLICY billing_period_scope ON public.billing_period
FOR SELECT USING (public.is_property_member(property_uuid)
  OR public.is_property_tenant(property_uuid));
DROP POLICY IF EXISTS billing_period_owner_write ON public.billing_period;
CREATE POLICY billing_period_owner_write ON public.billing_period
FOR ALL USING (public.is_property_member(property_uuid, ARRAY['owner'])
  OR public.is_system_admin())
WITH CHECK (public.is_property_member(property_uuid, ARRAY['owner'])
  OR public.is_system_admin());

DROP POLICY IF EXISTS bill_scope ON public.bill;
CREATE POLICY bill_scope ON public.bill
FOR SELECT USING (tenant_account_uuid = auth.uid()
  OR public.is_property_member(property_uuid));
DROP POLICY IF EXISTS bill_owner_write ON public.bill;
CREATE POLICY bill_owner_write ON public.bill
FOR ALL USING (public.is_property_member(property_uuid)
  OR public.is_system_admin())
WITH CHECK (public.is_property_member(property_uuid)
  OR public.is_system_admin());

DROP POLICY IF EXISTS bill_item_scope ON public.bill_item;
CREATE POLICY bill_item_scope ON public.bill_item
FOR SELECT USING (public.is_property_member(property_uuid)
  OR EXISTS (SELECT 1 FROM public.bill b
             WHERE b.uuid = bill_item.bill_uuid
               AND b.tenant_account_uuid = auth.uid()));
DROP POLICY IF EXISTS bill_item_write ON public.bill_item;
CREATE POLICY bill_item_write ON public.bill_item
FOR ALL USING (public.is_property_member(property_uuid))
WITH CHECK (public.is_property_member(property_uuid));

DROP POLICY IF EXISTS bill_adjustment_scope ON public.bill_adjustment;
CREATE POLICY bill_adjustment_scope ON public.bill_adjustment
FOR SELECT USING (public.is_property_member(property_uuid)
  OR EXISTS (SELECT 1 FROM public.bill b
             WHERE b.uuid = bill_adjustment.bill_uuid
               AND b.tenant_account_uuid = auth.uid()));
DROP POLICY IF EXISTS bill_adjustment_owner_write ON public.bill_adjustment;
CREATE POLICY bill_adjustment_owner_write ON public.bill_adjustment
FOR ALL USING (public.is_property_member(property_uuid))
WITH CHECK (public.is_property_member(property_uuid));

-- Payments and receipts
DROP POLICY IF EXISTS payment_submission_scope ON public.payment_submission;
CREATE POLICY payment_submission_scope ON public.payment_submission
FOR SELECT USING (tenant_account_uuid = auth.uid()
  OR public.is_property_member(property_uuid));
DROP POLICY IF EXISTS payment_submission_tenant_insert ON public.payment_submission;
CREATE POLICY payment_submission_tenant_insert ON public.payment_submission
FOR INSERT WITH CHECK (tenant_account_uuid = auth.uid()
  AND EXISTS (SELECT 1 FROM public.bill b
              WHERE b.uuid = bill_uuid
                AND b.tenant_account_uuid = auth.uid()
                AND b.archived_at IS NULL));
DROP POLICY IF EXISTS payment_submission_member_update ON public.payment_submission;
CREATE POLICY payment_submission_member_update ON public.payment_submission
FOR UPDATE USING (public.is_property_member(property_uuid))
WITH CHECK (public.is_property_member(property_uuid));

DROP POLICY IF EXISTS payment_receipt_scope ON public.payment_receipt;
CREATE POLICY payment_receipt_scope ON public.payment_receipt
FOR SELECT USING (tenant_account_uuid = auth.uid()
  OR EXISTS (SELECT 1 FROM public.payment_submission s
             WHERE s.uuid = submission_uuid
               AND public.is_property_member(s.property_uuid)));
DROP POLICY IF EXISTS payment_receipt_tenant_insert ON public.payment_receipt;
CREATE POLICY payment_receipt_tenant_insert ON public.payment_receipt
FOR INSERT WITH CHECK (tenant_account_uuid = auth.uid()
  AND EXISTS (SELECT 1 FROM public.payment_submission s
              WHERE s.uuid = submission_uuid
                AND s.tenant_account_uuid = auth.uid()));

DROP POLICY IF EXISTS payment_verification_scope ON public.payment_verification;
CREATE POLICY payment_verification_scope ON public.payment_verification
FOR SELECT USING (public.is_property_member(property_uuid)
  OR EXISTS (SELECT 1 FROM public.payment_submission s
             WHERE s.uuid = submission_uuid
               AND s.tenant_account_uuid = auth.uid()));
DROP POLICY IF EXISTS payment_verification_member_write ON public.payment_verification;
CREATE POLICY payment_verification_member_write ON public.payment_verification
FOR ALL USING (public.is_property_member(property_uuid))
WITH CHECK (public.is_property_member(property_uuid));

-- Notifications and public/privileged records
DROP POLICY IF EXISTS notification_own ON public.notification;
CREATE POLICY notification_own ON public.notification
FOR ALL USING (account_uuid = auth.uid() OR public.is_system_admin())
WITH CHECK (account_uuid = auth.uid() OR public.is_system_admin());

DROP POLICY IF EXISTS public_availability_guest ON public.public_availability;
CREATE POLICY public_availability_guest ON public.public_availability
FOR SELECT USING (published = true AND archived_at IS NULL);
DROP POLICY IF EXISTS public_availability_owner ON public.public_availability;
CREATE POLICY public_availability_owner ON public.public_availability
FOR ALL USING (public.is_property_member(property_uuid))
WITH CHECK (public.is_property_member(property_uuid));

DROP POLICY IF EXISTS property_inquiry_public_insert ON public.property_inquiry;
CREATE POLICY property_inquiry_public_insert ON public.property_inquiry
FOR INSERT WITH CHECK (EXISTS (
  SELECT 1 FROM public.property p
  WHERE p.uuid = property_uuid
    AND p.inquiry_enabled = true
    AND p.archived_at IS NULL
));
DROP POLICY IF EXISTS property_inquiry_owner_read ON public.property_inquiry;
CREATE POLICY property_inquiry_owner_read ON public.property_inquiry
FOR ALL USING (public.is_property_member(property_uuid)
  OR public.is_system_admin())
WITH CHECK (public.is_property_member(property_uuid)
  OR public.is_system_admin());

DROP POLICY IF EXISTS privacy_request_own ON public.privacy_request;
CREATE POLICY privacy_request_own ON public.privacy_request
FOR ALL USING (account_uuid = auth.uid() OR public.is_system_admin())
WITH CHECK (account_uuid = auth.uid() OR public.is_system_admin());

DROP POLICY IF EXISTS audit_event_read ON public.audit_event;
CREATE POLICY audit_event_read ON public.audit_event
FOR SELECT USING (actor_account_uuid = auth.uid()
  OR (property_uuid IS NOT NULL AND public.is_property_member(property_uuid))
  OR public.is_system_admin());
DROP POLICY IF EXISTS audit_event_insert ON public.audit_event;
CREATE POLICY audit_event_insert ON public.audit_event
FOR INSERT WITH CHECK (public.is_system_admin()
  OR actor_account_uuid = auth.uid()
  OR (property_uuid IS NOT NULL AND public.is_property_member(property_uuid)));

-- Private receipt bucket and storage policies
INSERT INTO storage.buckets (id, name, public)
VALUES ('payment_receipts', 'payment_receipts', false)
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS payment_receipts_tenant_read ON storage.objects;
CREATE POLICY payment_receipts_tenant_read ON storage.objects
FOR SELECT USING (
  bucket_id = 'payment_receipts'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS payment_receipts_tenant_insert ON storage.objects;
CREATE POLICY payment_receipts_tenant_insert ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'payment_receipts'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS payment_receipts_member_read ON storage.objects;
CREATE POLICY payment_receipts_member_read ON storage.objects
FOR SELECT USING (
  bucket_id = 'payment_receipts'
  AND EXISTS (
    SELECT 1
    FROM public.payment_receipt pr
    WHERE pr.storage_path = name
      AND public.is_property_member(
        (SELECT s.property_uuid
         FROM public.payment_submission s
         WHERE s.uuid = pr.submission_uuid)
      )
  )
);

COMMIT;
