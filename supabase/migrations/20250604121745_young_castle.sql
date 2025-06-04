/*
  # Initial SafeFood Platform Schema

  1. New Tables
    - users: Platform users with role-based access
    - organizations: Food donors (restaurants, hotels, stores)
    - donations: Food donation records
    - pickups: Donation pickup assignments
    - charities: Registered charitable organizations
    - volunteers: Registered volunteers
    - impact_metrics: Real-time impact tracking

  2. Security
    - Enable RLS on all tables
    - Policies for role-based access
    - Secure data access patterns
*/

-- Create enum types
CREATE TYPE user_role AS ENUM ('admin', 'donor', 'charity', 'volunteer');
CREATE TYPE donation_status AS ENUM ('pending', 'assigned', 'picked_up', 'delivered', 'cancelled');
CREATE TYPE food_type AS ENUM ('prepared_meals', 'groceries', 'produce', 'bakery', 'other');

-- Users table (extends Supabase auth)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT NOT NULL,
  phone TEXT,
  role user_role NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Organizations (food donors)
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  contact_person TEXT NOT NULL,
  contact_phone TEXT NOT NULL,
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Charities
CREATE TABLE charities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  name TEXT NOT NULL,
  registration_number TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  contact_person TEXT NOT NULL,
  contact_phone TEXT NOT NULL,
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Volunteers
CREATE TABLE volunteers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  available BOOLEAN DEFAULT true,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  last_active TIMESTAMPTZ,
  total_pickups INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 5.0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Donations
CREATE TABLE donations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) NOT NULL,
  food_type food_type NOT NULL,
  quantity INTEGER NOT NULL,
  description TEXT NOT NULL,
  expiry TIMESTAMPTZ NOT NULL,
  pickup_window_start TIMESTAMPTZ NOT NULL,
  pickup_window_end TIMESTAMPTZ NOT NULL,
  status donation_status DEFAULT 'pending',
  temperature_requirements TEXT,
  handling_instructions TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Pickups
CREATE TABLE pickups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  donation_id UUID REFERENCES donations(id) NOT NULL,
  charity_id UUID REFERENCES charities(id),
  volunteer_id UUID REFERENCES volunteers(id),
  assigned_at TIMESTAMPTZ DEFAULT now(),
  picked_up_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  proof_of_pickup TEXT,
  proof_of_delivery TEXT,
  notes TEXT,
  rating INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Impact metrics
CREATE TABLE impact_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  meals_saved INTEGER DEFAULT 0,
  kg_food_saved DECIMAL(10,2) DEFAULT 0,
  co2_saved DECIMAL(10,2) DEFAULT 0,
  beneficiaries_served INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE charities ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteers ENABLE ROW LEVEL SECURITY;
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE pickups ENABLE ROW LEVEL SECURITY;
ALTER TABLE impact_metrics ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can read their own data
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

-- Organizations
CREATE POLICY "Organizations visible to authenticated users" ON organizations
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Organizations can manage their own data" ON organizations
  USING (auth.uid() IN (
    SELECT user_id FROM users WHERE role = 'donor'
  ));

-- Charities
CREATE POLICY "Charities visible to authenticated users" ON charities
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Charities can manage their own data" ON charities
  USING (auth.uid() IN (
    SELECT user_id FROM users WHERE role = 'charity'
  ));

-- Volunteers
CREATE POLICY "Volunteers visible to authenticated users" ON volunteers
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Volunteers can manage their own data" ON volunteers
  USING (auth.uid() IN (
    SELECT user_id FROM users WHERE role = 'volunteer'
  ));

-- Donations
CREATE POLICY "Donations visible to authenticated users" ON donations
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Organizations can manage their donations" ON donations
  USING (organization_id IN (
    SELECT id FROM organizations WHERE user_id = auth.uid()
  ));

-- Pickups
CREATE POLICY "Pickups visible to relevant parties" ON pickups
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM volunteers WHERE id = volunteer_id
      UNION
      SELECT user_id FROM charities WHERE id = charity_id
      UNION
      SELECT o.user_id FROM organizations o
      JOIN donations d ON d.organization_id = o.id
      WHERE d.id = donation_id
    )
  );

-- Impact metrics visible to all authenticated users
CREATE POLICY "Impact metrics visible to authenticated users" ON impact_metrics
  FOR SELECT USING (auth.role() = 'authenticated');