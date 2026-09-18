/**
 * Gera PNGs nas resoluções oficiais a partir dos SVGs de branding.
 * Requer: npm install sharp (em admin_panel)
 */
const fs = require('fs');
const path = require('path');

const ASSETS = path.join(__dirname, '..', '..', 'assets', 'images', 'branding');

const COVERS = [
  {
    id: 'capa1',
    svg: 'sofia_capa1_luz_pureza.svg',
    prefix: 'capa_1_luz_pureza',
  },
  {
    id: 'capa2',
    svg: 'sofia_capa2_brilho_graca.svg',
    prefix: 'capa_2_brilho_graca',
  },
  {
    id: 'capa3',
    svg: 'sofia_capa3_majestade_serenidade.svg',
    prefix: 'capa_3_majestade_serenidade',
  },
];

const SIZES = {
  icon: { w: 512, h: 512, suffix: 'icon' },
  splash: { w: 1080, h: 1920, suffix: 'splash' },
  background: { w: 1242, h: 2208, suffix: 'background' },
};

async function main() {
  let sharp;
  const sharpPaths = [
    'sharp',
    path.join(__dirname, '..', '..', 'admin_panel', 'node_modules', 'sharp'),
  ];
  for (const mod of sharpPaths) {
    try {
      sharp = require(mod);
      break;
    } catch (_) {}
  }
  if (!sharp) {
    console.error('Instale sharp: cd admin_panel && npm install sharp');
    process.exit(1);
  }

  for (const cover of COVERS) {
    const svgPath = path.join(ASSETS, cover.svg);
    if (!fs.existsSync(svgPath)) {
      console.warn(`SVG ausente: ${cover.svg}`);
      continue;
    }
    const svgBuffer = fs.readFileSync(svgPath);
    for (const [key, size] of Object.entries(SIZES)) {
      const outName = `${cover.prefix}_${size.suffix}.png`;
      const outPath = path.join(ASSETS, outName);
      await sharp(svgBuffer)
        .resize(size.w, size.h, { fit: 'cover', background: { r: 255, g: 255, b: 255, alpha: 1 } })
        .png({ quality: 95, compressionLevel: 9 })
        .toFile(outPath);
      console.log(`✓ ${outName} (${size.w}x${size.h})`);
    }
  }
  console.log('PNGs gerados em assets/images/branding/');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
