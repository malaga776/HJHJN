import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { Auth } from '@supabase/auth-helpers-react';
import { supabase } from './lib/supabase';

function App() {
  const { t } = useTranslation();

  return (
    <Router>
      <div className="min-h-screen bg-primary-50 text-neutral-800" dir="rtl">
        <header className="bg-white shadow-sm">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
            <h1 className="text-3xl font-heading text-primary-500">
              {t('app.title')}
            </h1>
          </div>
        </header>
        <main>
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <Auth
              supabaseClient={supabase}
              appearance={{ theme: 'default' }}
              providers={[]}
            />
          </div>
        </main>
      </div>
    </Router>
  );
}

export default App;