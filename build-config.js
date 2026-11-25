// Netlify (деплой из Git / CLI): собирает config.js из переменных окружения SUPABASE_URL и SUPABASE_ANON_KEY.
// Если переменные не заданы, остаётся существующий config.js. Деплой «перетаскиванием» этот файл не запускает.
const fs = require('fs'), u = process.env.SUPABASE_URL, k = process.env.SUPABASE_ANON_KEY;
if (u && k) { fs.writeFileSync('config.js', 'window.TT_CONFIG = ' + JSON.stringify({ SUPABASE_URL: u, SUPABASE_ANON_KEY: k }, null, 2) + ';\n'); console.log('config.js создан из переменных окружения'); }
else console.log('SUPABASE_URL / SUPABASE_ANON_KEY не заданы: используется config.js из репозитория');
