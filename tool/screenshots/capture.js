const { chromium } = require('playwright');
const http = require('http'); const fs = require('fs'); const path = require('path');
// Captura pantallas de la build web con datos de ejemplo.
// Uso: flutter build web --release --no-web-resources-cdn
//      node tool/screenshots/capture.js [nombre...]   (salida en build/screenshots)
const root = path.resolve(__dirname, '../../build/web');
const outDir = path.resolve(__dirname, '../../build/screenshots');
fs.mkdirSync(outDir, {recursive: true});
const types = {'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.json':'application/json','.css':'text/css','.png':'image/png','.otf':'font/otf','.ttf':'font/ttf','.pdf':'application/pdf','.mjs':'application/javascript'};
const server = http.createServer((req,res)=>{ let p = decodeURIComponent(req.url.split('?')[0]); if(p==='/'||!fs.existsSync(path.join(root,p))) p='/index.html'; const f=path.join(root,p); res.writeHead(200,{'Content-Type':types[path.extname(f)]||'application/octet-stream'}); fs.createReadStream(f).pipe(res);}).listen(8099);
const docs = [
 {id:'w',title:'Bienvenida a Folio',fileName:'bienvenida.docx',kind:'word',source:'asset:assets/samples/bienvenida.docx',sizeBytes:37658,addedAt:'2026-11-14T10:00:00.000',progress:0.35,position:0},
 {id:'p',title:'Guía de lectura',fileName:'guia.pdf',kind:'pdf',source:'asset:assets/samples/guia.pdf',sizeBytes:4155,addedAt:'2026-11-13T10:00:00.000'},
 {id:'x',title:'Presupuesto mensual',fileName:'presupuesto.xlsx',kind:'spreadsheet',source:'asset:assets/samples/presupuesto.xlsx',sizeBytes:5962,addedAt:'2026-11-12T10:00:00.000'},
 {id:'m',title:'Notas de ideas',fileName:'notas.md',kind:'text',source:'asset:assets/samples/notas.md',sizeBytes:491,addedAt:'2026-11-11T10:00:00.000',progress:1},
];
const hl = [
 {id:'h1',documentId:'w',blockIndex:7,start:0,end:58,colorIndex:0,text:'Selecciona cualquier frase de este documento y elige un color',createdAt:'2026-11-14T11:00:00.000'},
 {id:'h2',documentId:'w',blockIndex:13,start:0,end:46,colorIndex:2,text:'Un sendero tranquilo se perdía tras la colina.',createdAt:'2026-11-14T11:05:00.000',note:'Me gusta el ritmo de esta frase.'},
 {id:'h3',documentId:'w',blockIndex:1,start:0,end:36,colorIndex:0,style:'underline',text:'Folio es un lector de documentos sin',createdAt:'2026-11-14T11:06:00.000'},
 {id:'h4',documentId:'p',blockIndex:1,start:0,end:20,colorIndex:1,text:'Leer bien empieza antes de abrir el documento.',createdAt:'2026-11-14T11:07:00.000',rects:[[40,452,380,440]]},
 {id:'h5',documentId:'p',blockIndex:1,start:30,end:60,colorIndex:0,style:'underline',text:'La pantalla debe acompañar, no competir.',createdAt:'2026-11-14T11:08:00.000',rects:[[40,438,330,427]]},
];
(async () => {
  const which = process.argv.slice(2);
  const browser = await chromium.launch();
  for (const [name, route, scheme, extra] of [
    ['library-light','/library','light',{}],
    ['library-dark','/library','dark',{}],
    ['reader-docx','/reader/w','light',{}],
    ['reader-docx-night','/reader/w','light',{'flutter.settings.readingTheme':'night'}],
    ['reader-md','/reader/m','light',{'flutter.settings.readingTheme':'sepia'}],
    ['reader-pdf','/reader/p','light',{}],
    ['reader-pdf-night','/reader/p','light',{'flutter.settings.pdfNightMode':true,'flutter.settings.lockRotation':true}],
    ['reader-xlsx','/reader/x','light',{}],
    ['highlights','/highlights','light',{}],
    ['settings','/settings','light',{}],
    ['empty','/library','light',{empty:true}],
  ]) {
    if (which.length && !which.includes(name)) continue;
    const ctx = await browser.newContext({viewport:{width:390,height:844}, deviceScaleFactor:2, colorScheme:scheme, locale:'es-ES'});
    const page = await ctx.newPage();
    page.on('console', m => { if (m.type()==='error') console.log(name, 'console:', m.text().slice(0,200)); });
    await page.addInitScript(([docs,hl,extra]) => {
      localStorage.clear();
      if (!extra.empty) {
        localStorage.setItem('flutter.library.documents.v1', JSON.stringify(JSON.stringify(docs)));
        localStorage.setItem('flutter.highlights.v1', JSON.stringify(JSON.stringify(hl)));
      }
      for (const [k,v] of Object.entries(extra)) if (k!=='empty') localStorage.setItem(k, JSON.stringify(v));
    }, [docs,hl,extra]);
    await page.goto('http://localhost:8099/#'+route);
    await page.waitForTimeout(9000);
    await page.screenshot({path: path.join(outDir, `${name}.png`)});
    await ctx.close();
  }
  await browser.close(); server.close();
})();
