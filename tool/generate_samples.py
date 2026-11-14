# Genera los documentos de ejemplo de assets/samples/.
# Uso: python3 tool/generate_samples.py assets/samples
# Requiere: pip install python-docx openpyxl reportlab
import sys, datetime
out = sys.argv[1]
# DOCX
from docx import Document
from docx.shared import Pt
d = Document()
d.core_properties.title = 'Bienvenida a Folio'
d.add_heading('Bienvenida a Folio', 0)
p = d.add_paragraph('Folio es un lector de documentos ')
p.add_run('sin anuncios').bold = True
p.add_run(', sin distracciones y pensado para leer con calma. Abre tus archivos de ')
p.add_run('Word, PDF, Excel').italic = True
p.add_run(' y texto en un solo lugar.')
d.add_heading('Lo esencial', 1)
d.add_paragraph('Toca el botón + de la biblioteca para abrir un archivo.', style='List Number')
d.add_paragraph('Mantén pulsado un documento para renombrarlo, compartirlo o quitarlo.', style='List Number')
d.add_paragraph('Usa el botón Lectura para cambiar el tamaño de letra y el ambiente.', style='List Number')
d.add_heading('Subrayar', 1)
d.add_paragraph('Selecciona cualquier frase de este documento y elige un color en la barra flotante. Tus subrayados aparecen en la pestaña Subrayados, agrupados por documento.')
d.add_paragraph('Los colores son suaves para no cansar la vista.', style='List Bullet')
d.add_paragraph('Puedes copiar el texto seleccionado con un toque.', style='List Bullet')
d.add_heading('Formatos compatibles', 2)
t = d.add_table(rows=1, cols=3)
t.style = 'Table Grid'
for i, h in enumerate(['Formato', 'Extensiones', 'Visor']):
    t.rows[0].cells[i].text = h
for row in [('PDF', '.pdf', 'Páginas con zoom'), ('Word', '.docx', 'Lectura fluida'), ('Excel', '.xlsx, .csv', 'Cuadrícula'), ('Texto', '.txt, .md', 'Lectura fluida')]:
    cells = t.add_row().cells
    for i, v in enumerate(row): cells[i].text = v
d.add_heading('Una página para leer', 1)
for txt in [
 'Un sendero tranquilo se perdía tras la colina. La calle estaba vacía, pero las ventanas seguían iluminadas, y el pavimento mojado empezó a brillar bajo las farolas.',
 'Clara abrió la puerta de una pequeña librería. Dentro, alguien leía junto a la ventana, ajeno al ruido de la ciudad. Olía a papel y a café recién hecho.',
 'Hay lecturas que piden silencio. Esta aplicación existe para dárselo: nada de banners, nada de ventanas emergentes, solo el texto y tú.',
]:
    d.add_paragraph(txt)
d.save(f'{out}/bienvenida.docx')

# XLSX
from openpyxl import Workbook
from openpyxl.styles import Font
wb = Workbook(); ws = wb.active; ws.title = 'Noviembre'
ws.append(['Fecha', 'Concepto', 'Categoría', 'Importe'])
rows = [
 (datetime.date(2026,11,1),'Alquiler','Vivienda',-650),
 (datetime.date(2026,11,2),'Nómina','Ingresos',1850),
 (datetime.date(2026,11,4),'Supermercado','Comida',-82.4),
 (datetime.date(2026,11,7),'Transporte mensual','Transporte',-40),
 (datetime.date(2026,11,9),'Librería','Ocio',-23.9),
 (datetime.date(2026,11,12),'Luz','Vivienda',-47.35),
 (datetime.date(2026,11,15),'Cena con amigos','Ocio',-36),
 (datetime.date(2026,11,18),'Supermercado','Comida',-64.1),
 (datetime.date(2026,11,21),'Internet','Vivienda',-30),
 (datetime.date(2026,11,25),'Farmacia','Salud',-12.5),
]
for r in rows: ws.append(list(r))
ws.append([None,'Saldo',None,round(sum(r[3] for r in rows),2)])
for c in ws[1]: c.font = Font(bold=True)
for row in ws.iter_rows(min_row=2, max_col=1):
    for c in row: c.number_format = 'dd/mm/yyyy'
ws2 = wb.create_sheet('Resumen')
ws2.append(['Categoría','Total'])
for cat,val in [('Vivienda',-727.35),('Comida',-146.5),('Ocio',-59.9),('Transporte',-40),('Salud',-12.5),('Ingresos',1850)]:
    ws2.append([cat,val])
wb.save(f'{out}/presupuesto.xlsx')

# PDF
from reportlab.lib.pagesizes import A5
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
ss = getSampleStyleSheet()
body = ParagraphStyle('b', parent=ss['BodyText'], fontName='Times-Roman', fontSize=11.5, leading=17)
h = ParagraphStyle('h', parent=ss['Title'], fontName='Times-Bold', fontSize=24, leading=28, spaceAfter=14)
h2 = ParagraphStyle('h2', parent=ss['Heading2'], fontName='Times-Bold', fontSize=15, spaceBefore=10)
story = [Spacer(1,40), Paragraph('Guía de lectura', h), Paragraph('Cómo leer mejor en pantalla', ss['Italic']), Spacer(1,20)]
chapters = [
 ('1. Elige el momento', 'Leer bien empieza antes de abrir el documento. Busca un rato sin notificaciones y un lugar con luz suave. La pantalla debe acompañar, no competir.'),
 ('2. Ajusta la página', 'Un tamaño de letra cómodo y un interlineado generoso reducen el cansancio. En los documentos de texto puedes cambiar ambos desde el botón Lectura.'),
 ('3. Subraya lo importante', 'Subrayar obliga a decidir qué importa. Hazlo con moderación: si todo está resaltado, nada lo está.'),
 ('4. Vuelve a lo leído', 'Folio recuerda la página por la que ibas. Cuando vuelvas, el documento se abrirá justo donde lo dejaste.'),
]
for i,(t,p) in enumerate(chapters):
    if i: story.append(PageBreak())
    story.append(Paragraph(t, h2))
    for _ in range(3): story.append(Paragraph(p, body)); story.append(Spacer(1,8))
SimpleDocTemplate(f'{out}/guia.pdf', pagesize=A5, title='Guía de lectura', leftMargin=40, rightMargin=40).build(story)

open(f'{out}/notas.md','w').write('''# Notas de ideas

Pequeño cuaderno en **Markdown** para probar el lector de texto.

## Para esta semana

- Terminar el informe trimestral
- Leer *dos capítulos* de la guía
  - Subrayar las ideas clave
- Revisar el presupuesto de noviembre

## Una cita

> La lectura es a la mente lo que el ejercicio es al cuerpo.

## Pendientes técnicos

1. Probar archivos `.docx` largos
2. Abrir hojas de cálculo con varias pestañas
3. Comprobar el modo noche

---

Escrito con calma, sin anuncios.
''')
