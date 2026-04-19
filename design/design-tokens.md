# FitClub — Design Tokens

Extraits des maquettes (10 écrans).

## Couleurs (Material Design 3 - Tonal Palette)

### Primary (Bleu Marine)
- `primary`: #00236f
- `primary-container`: #1e3a8a
- `primary-fixed`: #dce1ff
- `primary-fixed-dim`: #b6c4ff
- `on-primary`: #ffffff
- `on-primary-container`: #90a8ff

### Secondary (Orange Énergie)
- `secondary`: #9d4300
- `secondary-container`: #fd761a
- `secondary-fixed`: #ffdbca
- `secondary-fixed-dim`: #ffb690
- `on-secondary`: #ffffff
- `on-secondary-container`: #5c2400

### Tertiary (Marron Terre)
- `tertiary`: #4b1c00
- `tertiary-container`: #6e2c00
- `tertiary-fixed`: #ffdbcb
- `tertiary-fixed-dim`: #ffb691

### Error
- `error`: #ba1a1a
- `error-container`: #ffdad6
- `on-error`: #ffffff

### Surfaces
- `surface`: #f6fafe
- `surface-dim`: #d6dade
- `surface-bright`: #f6fafe
- `surface-container-lowest`: #ffffff
- `surface-container-low`: #f0f4f8
- `surface-container`: #eaeef2
- `surface-container-high`: #e4e9ed
- `surface-container-highest`: #dfe3e7
- `on-surface`: #171c1f
- `on-surface-variant`: #444651
- `outline`: #757682
- `outline-variant`: #c5c5d3

### Status Colors (via Tailwind)
- Actif: `bg-green-50 text-green-700`
- Expiré: `bg-red-50 text-red-700`
- Suspendu: `bg-orange-50 text-orange-700`
- Check-in OK: `bg-emerald-50` + `bg-emerald-500` (icon)
- Check-in Refusé: `bg-red-50` + `bg-red-500` (icon)
- Check-in Warning: `bg-orange-100` + `text-orange-600`

## Typographie

### Fonts
- **Headline**: Manrope (600, 700, 800)
- **Body**: Inter (400, 500, 600)
- **Label**: Inter (400, 500, 600)

### Usage
- Titres de page: `font-headline text-3xl md:text-4xl font-extrabold`
- Sous-titres: `font-headline text-xl font-bold`
- KPI values: `font-headline text-3xl font-bold`
- Body: `font-body text-sm`
- Labels: `font-label text-xs font-bold uppercase tracking-wider`
- Badges: `text-[10px] font-bold uppercase tracking-widest`

## Border Radius
- Cards: `rounded-2xl` ou `rounded-3xl`
- Buttons: `rounded-xl`
- Inputs: `rounded-xl`
- Avatars: `rounded-full`
- Badges: `rounded-full`
- Bottom nav: `rounded-t-3xl`

## Shadows
- Cards: `shadow-[0_20px_40px_-10px_rgba(23,28,31,0.06)]`
- Auth card: `shadow-[0_20px_40px_-10px_rgba(23,28,31,0.06)]`
- Bottom nav: `shadow-[0_-10px_30px_-15px_rgba(0,0,0,0.1)]`
- CTA buttons: `shadow-lg shadow-secondary/20`
- Status glow: `shadow-[0_0_12px_rgba(253,118,26,0.5)]`

## Layout

### Sidebar (Desktop)
- Largeur: `w-64`
- Background: `bg-slate-100`
- Item actif: `bg-white rounded-lg shadow-sm translate-x-1`
- Item inactif: `text-slate-600 hover:text-blue-800 hover:bg-white/50`

### Bottom Nav (Mobile)
- Background: `bg-white/70 backdrop-blur-md`
- Tab actif: `bg-orange-100 text-orange-700 rounded-2xl`
- Tab inactif: `text-slate-400`
- Padding bottom: `pb-6` (safe area)

### Top Bar
- Background: `bg-slate-50`
- Sticky: `sticky top-0 z-30`

### Content
- Main padding: `p-6 md:p-12`
- Max width: `max-w-7xl mx-auto`
- Content offset desktop: `md:ml-64`

## Composants Clés

### KPI Cards
- Background: `bg-surface-container-lowest`
- Icon container: `p-3 rounded-xl` avec couleur tonal
- Trend badge: `text-xs font-bold bg-green-50 text-green-600 px-2 py-1 rounded-lg`

### Table
- Header: `bg-surface-container-low/50`
- Header text: `text-xs font-bold uppercase tracking-wider text-outline`
- Row hover: `hover:bg-surface-container-low/30`
- Actions: visibles au hover (`opacity-0 group-hover:opacity-100`)

### Buttons
- Primary CTA: `bg-gradient-to-r from-primary to-primary-container text-on-primary font-bold`
- Secondary CTA: `bg-gradient-to-br from-secondary to-secondary-container text-white font-bold`
- Outline: `border-2 border-primary text-primary`
- Ghost: `text-slate-500 hover:text-primary`

### Status Badges
- `px-3 py-1 rounded-full text-xs font-bold`
- Actif: `bg-green-50 text-green-700`
- Expiré: `bg-red-50 text-red-700`
- Suspendu: `bg-orange-50 text-orange-700`

### Inputs
- `bg-surface-container-low border-none rounded-xl px-4 py-3`
- Focus: `focus:ring-2 focus:ring-primary-fixed focus:bg-white`
- Icon prefix: `pl-12` avec icône absolute left

### Stepper (Inscription)
- Active: `bg-secondary text-on-secondary ring-4 ring-secondary-fixed`
- Done: `bg-primary text-on-primary` + check icon
- Inactive: `bg-surface-container-highest text-on-surface-variant`
- Connector done: `h-px bg-primary`
- Connector pending: `h-px bg-surface-container-highest`

## Icônes

Material Symbols Outlined (Google Fonts), principales icônes utilisées :
- Navigation: dashboard, group, payments, diversity_3, qr_code_scanner, settings, notifications
- Actions: add, arrow_forward, arrow_back, visibility, edit_note, more_vert, check_circle
- Membres: person, person_pin_circle, admin_panel_settings, manage_accounts, sports_gymnastics
- Finance: payments, credit_card, account_balance, euro_symbol
- Status: check_circle, block, priority_high, bolt, timer
- QR: qr_code, qr_code_scanner
- Media: photo_camera, add_a_photo, fitness_center
