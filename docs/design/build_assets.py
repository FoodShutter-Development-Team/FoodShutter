from pathlib import Path
from html import escape
import xml.etree.ElementTree as ET
import base64

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'docs' / 'assets'
DEST.mkdir(parents=True, exist_ok=True)
INK, MUTED, LINE = '#3d3d3a', '#63635e', '#8b9a7e'

# Color names and values match Core/Shared Color+Custom.swift.
PAPER = '#fafaf0'
SURFACE = '#f0eee7'
ACCENT = '#d2785a'
PROTEIN = '#7b9fad'
FAT = '#c9a96e'
CARB = '#8b9a7e'
SERIF = 'Georgia, Times New Roman, serif'

def write_svg(name, width, height, title, body):
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title">
<title id="title">{escape(title)}</title>
<style>@media(prefers-reduced-motion:reduce){{.motion{{display:none}}}}</style>
<rect width="{width}" height="{height}" rx="24" fill="{PAPER}"/>
<g font-family="{SERIF}" fill="{INK}">{body}</g>
</svg>
'''
    (DEST/name).write_text(svg,encoding='utf-8')

def brand_hero():
    icon=base64.b64encode((ROOT/'Appendix/appIcon.png').read_bytes()).decode()
    body=f'''<image x="54" y="40" width="70" height="70" href="data:image/png;base64,{icon}"/>
<text x="146" y="94" font-size="64" font-weight="700">FoodShutter</text>
<text x="54" y="165" font-size="32">Photograph a meal.</text>
<text x="54" y="207" font-size="32">Review its nutrition.</text>
<text x="56" y="258" font-size="18" fill="{MUTED}">Native capture, ingredient detail and a shared meal history.</text>
<path d="M54 292H688" stroke="#d8d6cd"/>
<text x="54" y="325" font-size="16" fill="{MUTED}">SwiftUI</text>
<text x="200" y="325" font-size="16" fill="{MUTED}">FastAPI</text>
<text x="346" y="325" font-size="16" fill="{MUTED}">Supabase</text>
<text x="492" y="325" font-size="16" fill="{MUTED}">Next.js</text>
<circle cx="974" cy="176" r="113" fill="none" stroke="{SURFACE}" stroke-width="23"/>
<g transform="rotate(-90 974 176)">
<circle cx="974" cy="176" r="113" fill="none" stroke="{PROTEIN}" stroke-width="23" pathLength="100" stroke-dasharray="43 100"/>
<circle cx="974" cy="176" r="113" fill="none" stroke="{FAT}" stroke-width="23" pathLength="100" stroke-dasharray="12 100" stroke-dashoffset="-44"/>
<circle cx="974" cy="176" r="113" fill="none" stroke="{CARB}" stroke-width="23" pathLength="100" stroke-dasharray="43 100" stroke-dashoffset="-57"/>
</g>
<text x="974" y="170" text-anchor="middle" font-size="32" font-weight="700">Meal</text>
<text x="974" y="204" text-anchor="middle" font-size="25">nutrition</text>
<g class="motion"><circle cx="974" cy="176" r="133" fill="none" stroke="{ACCENT}" stroke-width="1.5" opacity="0.25"><animate attributeName="r" values="130;136;130" dur="6s" repeatCount="indefinite"/><animate attributeName="opacity" values="0.15;0.45;0.15" dur="6s" repeatCount="indefinite"/></circle></g>
<circle cx="846" cy="329" r="5" fill="{PROTEIN}"/><text x="860" y="335" font-size="15" fill="{MUTED}">Protein</text>
<circle cx="965" cy="329" r="5" fill="{FAT}"/><text x="979" y="335" font-size="15" fill="{MUTED}">Fat</text>
<circle cx="1050" cy="329" r="5" fill="{CARB}"/><text x="1064" y="335" font-size="15" fill="{MUTED}">Carbs</text>'''
    write_svg('foodshutter-hero.svg',1260,370,'FoodShutter: photograph a meal and review its nutrition',body)
    chinese=body.replace('Photograph a meal.','拍摄餐食。').replace('Review its nutrition.','查看营养。').replace('Native capture, ingredient detail and a shared meal history.','原生拍摄、食材明细与跨设备餐食记录。')
    write_svg('foodshutter-hero.zh-CN.svg',1260,370,'FoodShutter：拍摄餐食，查看营养',chinese)

def sections_and_navigation():
    sections={
      'demo':'The complete film', 'features':'What FoodShutter does',
      'architecture':'System architecture', 'pipeline':'Eight-step analysis',
      'structure':'Repository structure', 'setup':'Run locally',
      'evaluation':'Evaluation and engineering', 'team':'The course team',
      'contributing':'Contributing and license'
    }
    for name,label in sections.items():
        body=f'<rect x="0" y="12" width="4" height="46" rx="2" fill="{ACCENT}"/><text x="26" y="48" font-size="32" font-weight="700">{escape(label)}</text><path d="M26 69H1230" stroke="#d8d6cd"/>'
        write_svg(f'section-{name}.svg',1260,78,label,body)
    zh_labels={'demo':'完整宣传演示','features':'功能与体验','architecture':'系统架构','pipeline':'八步分析流程','structure':'项目结构','setup':'运行指南','evaluation':'评估与工程质量','team':'课程项目团队','contributing':'开发与许可'}
    for name,label in zh_labels.items():
        body=f'<rect x="0" y="12" width="4" height="46" rx="2" fill="{ACCENT}"/><text x="26" y="48" font-family="Georgia, Noto Serif CJK SC, SimSun, serif" font-size="32" font-weight="700">{escape(label)}</text><path d="M26 69H1230" stroke="#d8d6cd"/>'
        write_svg(f'section-{name}.zh-CN.svg',1260,78,label,body)
    buttons={'film':'Watch the film','setup':'Get started','architecture':'Architecture','chinese':'简体中文','english':'English'}
    for name,label in buttons.items():
        family='Georgia, Noto Serif CJK SC, SimSun, serif' if name=='chinese' else SERIF
        body=f'<rect x="1" y="1" width="298" height="58" rx="28" fill="{SURFACE}" stroke="#d8d6cd"/><text x="150" y="38" text-anchor="middle" font-family="{family}" font-size="22" font-weight="700" fill="{ACCENT}">{escape(label)}</text>'
        write_svg(f'nav-{name}.svg',300,60,label,body)
    body=f'<path d="M30 8H1230" stroke="#d8d6cd"/><text x="30" y="48" font-size="26" font-weight="700">FoodShutter</text><text x="1230" y="46" text-anchor="end" font-size="17" fill="{MUTED}">Photo-based nutrition tracking</text>'
    write_svg('foodshutter-footer.svg',1260,72,'FoodShutter: photo-based nutrition tracking',body)

brand_hero()
sections_and_navigation()

def diagram(name, title, subtitle, width, height, boxes, edges, footer):
    graph = ET.Element('mxGraphModel', adaptiveColors='auto', grid='1', gridSize='10', page='1',
                       pageWidth=str(width), pageHeight=str(height), background='#fafaf0')
    root = ET.SubElement(graph, 'root')
    ET.SubElement(root, 'mxCell', id='0')
    ET.SubElement(root, 'mxCell', id='1', parent='0')
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
           f'<title id="title">{escape(title)}</title><desc id="desc">{escape(subtitle)}</desc>',
           '<style>@media(prefers-reduced-motion:reduce){.motion{display:none}}</style>',
           '<defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto-start-reverse" markerUnits="userSpaceOnUse"><path d="M1 1 L8 5 L1 9" fill="none" stroke="#8b9a7e" stroke-width="1.8"/></marker></defs>',
           f'<rect width="{width}" height="{height}" rx="24" fill="#fafaf0"/>',
           '<g font-family="Georgia, Times New Roman, serif">',
           f'<text x="40" y="53" font-size="32" font-weight="700" fill="{INK}">{escape(title)}</text>',
           f'<text x="40" y="85" font-size="16" fill="{MUTED}">{escape(subtitle)}</text>']
    for id_, x, y, w, h, heading, lines, accent, fill in boxes:
        label = '<b>'+escape(heading)+'</b><br/>'+'<br/>'.join(escape(t) for t in lines)
        cell = ET.SubElement(root, 'mxCell', id=id_, value=label, parent='1', vertex='1',
                             style=f'rounded=1;whiteSpace=wrap;html=1;fillColor={fill};strokeColor={accent};fontColor={INK};fontSize=16;fontFamily=Georgia;align=left;verticalAlign=middle;spacing=20;')
        ET.SubElement(cell, 'mxGeometry', x=str(x), y=str(y), width=str(w), height=str(h), attrib={'as':'geometry'})
        svg += [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="16" fill="{fill}" stroke="{accent}" stroke-width="1.3"/>',
                f'<rect x="{x}" y="{y+19}" width="4" height="{h-38}" rx="2" fill="{accent}"/>',
                f'<text x="{x+20}" y="{y+34}" font-size="20" font-weight="700" fill="{INK}">{escape(heading)}</text>']
        for i, line in enumerate(lines):
            svg.append(f'<text x="{x+20}" y="{y+62+i*24}" font-size="15" fill="{MUTED}">{escape(line)}</text>')
    for i, (source, target, points, label, lx, ly, bidirectional) in enumerate(edges):
        cell = ET.SubElement(root, 'mxCell', id=f'e{i}', value=label, parent='1', edge='1', source=source, target=target,
                             style='edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;strokeColor='+LINE+';fontColor='+MUTED+';fontSize=13;fontFamily=Georgia;'+('startArrow=block;startFill=0;' if bidirectional else ''))
        geo=ET.SubElement(cell,'mxGeometry',relative='1',attrib={'as':'geometry'})
        if len(points)>2:
            arr=ET.SubElement(geo,'Array',attrib={'as':'points'})
            for px,py in points[1:-1]: ET.SubElement(arr,'mxPoint',x=str(px),y=str(py))
        coords=' '.join(f'{x},{y}' for x,y in points)
        svg.append(f'<polyline points="{coords}" fill="none" stroke="{LINE}" stroke-width="1.8" stroke-linejoin="round" marker-end="url(#arrow)"'+(' marker-start="url(#arrow)"' if bidirectional else '')+'/>')
        # The motion illustrates data movement; it is not live processing status.
        motion_path='M'+' L'.join(f'{px} {py}' for px,py in points)
        begin=i*0.8
        svg.append(f'<circle class="motion" r="3.5" fill="#d2785a" opacity="0"><animate attributeName="opacity" values="0;0.8;0" dur="8s" begin="{begin}s" repeatCount="indefinite"/><animateMotion path="{motion_path}" dur="8s" begin="{begin}s" repeatCount="indefinite"/></circle>')
        if label:
            labelwidth=len(label)*7.3+16
            svg.append(f'<rect x="{lx-labelwidth/2}" y="{ly-15}" width="{labelwidth}" height="22" rx="5" fill="#fafaf0"/>')
            svg.append(f'<text x="{lx}" y="{ly}" text-anchor="middle" font-size="13" fill="{MUTED}">{escape(label)}</text>')
    svg += [f'<line x1="40" y1="{height-68}" x2="{width-40}" y2="{height-68}" stroke="#d8d6cd"/>',
            f'<text x="40" y="{height-35}" font-size="14" fill="{MUTED}">{escape(footer)}</text>', '</g></svg>']
    xml=ET.tostring(graph,encoding='unicode')
    (DEST/f'{name}.drawio').write_text(xml+'\n',encoding='utf-8')
    # Native SVG documentation asset. Its embedded mxGraphModel preserves editability.
    svg[0]=svg[0].replace(' role=',f' content="{escape(xml,quote=True)}" role=')
    (DEST/f'{name}.drawio.svg').write_text('\n'.join(svg)+'\n',encoding='utf-8')

diagram('system-architecture','FoodShutter system architecture',
        'Native capture, staged analysis, shared meal records and a web companion',1300,650,[
 ('ios',40,140,250,130,'iOS app',['SwiftUI + MVVM','Camera, dish detail, history'],'#d2785a','#f0eee7'),
 ('web',40,400,250,130,'Web companion',['Next.js 16 + React 19','Dashboard, history, statistics'],'#8b9a7e','#f0eee7'),
 ('api',490,140,270,130,'Analysis service',['FastAPI + BackgroundTasks','Eight steps; per-dish workers'],'#d2785a','#f0eee7'),
 ('supabase',490,400,270,130,'Supabase',['Auth, PostgreSQL, Storage','Realtime meal status updates'],'#8b9a7e','#f0eee7'),
 ('models',980,140,280,130,'Model endpoint',['OpenAI-compatible API','Vision + structured JSON'],'#7b9fad','#f0eee7'),
 ('index',980,400,280,130,'Nutrition index',['ChromaDB + BGE embeddings','USDA Foundation Foods'],'#7b9fad','#f0eee7')], [
 ('ios','api',[(290,190),(480,190)],'Photo + bearer token',385,174,False),
 ('api','models',[(760,190),(970,190)],'Schema-bound requests',865,174,False),
 ('api','supabase',[(625,270),(625,390)],'Persist staged results',625,337,False),
 ('ios','supabase',[(290,240),(360,240),(360,425),(480,425)],'Auth + Realtime + REST',357,334,True),
 ('web','supabase',[(290,480),(480,480)],'Auth + table reads',385,464,True),
 ('api','index',[(760,240),(880,240),(880,455),(970,455)],'Ingredient retrieval',880,337,False)],
 'Cloud credentials stay on the server. The current worker runs in-process; external service setup is required.')

diagram('analysis-pipeline','Eight-step food analysis',
        'Early dish results precede nutrition and optional personalized advice',1260,620,[
 ('s1',40,140,260,120,'01  Detect dishes',['Full image; names + boxes','Vision model + JSON schema'],'#d2785a','#f0eee7'),
 ('s2',340,140,260,120,'02  Filter boxes',['NMS, containment, area','Normalize and flag edges'],'#d2785a','#f0eee7'),
 ('s3',640,140,260,120,'03  Check count',['Guard against heavy filtering','Publish dishes_ready'],'#d2785a','#f0eee7'),
 ('s4',940,140,280,120,'04  Analyze each dish',['Full context + marked box','Ingredient and gram estimates'],'#8b9a7e','#f0eee7'),
 ('s5',940,390,280,120,'05  Retrieve nutrients',['Top-3 ingredient candidates','ChromaDB + BGE'],'#8b9a7e','#f0eee7'),
 ('s6',640,390,260,120,'06  Select or estimate',['Database candidate selection','Provenance + confidence'],'#8b9a7e','#f0eee7'),
 ('s7',340,390,260,120,'07  Assemble totals',['Scale nutrients by grams','Compute dish + meal macros'],'#8b9a7e','#f0eee7'),
 ('s8',40,390,260,120,'08  Generate advice',['Profile + dietary history','Persist advice; complete'],'#7b9fad','#f0eee7')],[
 ('s1','s2',[(300,200),(330,200)],'',0,0,False),
 ('s2','s3',[(600,200),(630,200)],'',0,0,False),
 ('s3','s4',[(900,200),(930,200)],'',0,0,False),
 ('s4','s5',[(1080,260),(1080,380)],'Up to four workers per stage',1080,332,False),
 ('s5','s6',[(940,450),(910,450)],'',0,0,False),
 ('s6','s7',[(640,450),(610,450)],'',0,0,False),
 ('s7','s8',[(340,450),(310,450)],'',0,0,False)],
 'Steps 4, 5 and 6 parallelize across dishes. Database misses remain explicit estimates; advice failure preserves nutrition.')

print('Wrote editable diagram sources and SVG documentation assets.')
