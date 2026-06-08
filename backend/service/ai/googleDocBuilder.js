const rgb = (hex) => {
  const value = hex.replace('#', '');
  return {
    red: parseInt(value.slice(0, 2), 16) / 255,
    green: parseInt(value.slice(2, 4), 16) / 255,
    blue: parseInt(value.slice(4, 6), 16) / 255,
  };
};

const pt = (magnitude) => ({ magnitude, unit: 'PT' });

const TEMPLATE = {
  fontFamily: 'Arial',
  colors: {
    text: rgb('000000'),
    heading: rgb('434343'),
  },
  textStyles: {
    title: { bold: true, fontSize: 20, foregroundColor: rgb('000000') },
    heading1: { bold: true, fontSize: 16, foregroundColor: rgb('000000') },
    heading2: { bold: true, fontSize: 14, foregroundColor: rgb('434343') },
    heading3: { bold: true, fontSize: 12, foregroundColor: rgb('434343') },
    body: { fontSize: 11, foregroundColor: rgb('000000') },
    label: { bold: true, fontSize: 11, foregroundColor: rgb('000000') },
    table: { fontSize: 10, foregroundColor: rgb('000000') },
  },
  paragraphStyles: {
    title: {
      namedStyleType: 'TITLE',
      spaceAbove: 0,
      spaceBelow: 12,
      lineSpacing: 115,
      keepWithNext: true,
    },
    heading1: {
      namedStyleType: 'HEADING_2',
      spaceAbove: 18,
      spaceBelow: 6,
      lineSpacing: 115,
      keepWithNext: true,
    },
    heading2: {
      namedStyleType: 'HEADING_3',
      spaceAbove: 16,
      spaceBelow: 4,
      lineSpacing: 115,
      keepWithNext: true,
    },
    heading3: {
      namedStyleType: 'HEADING_4',
      spaceAbove: 12,
      spaceBelow: 4,
      lineSpacing: 115,
      keepWithNext: true,
    },
    body: {
      namedStyleType: 'NORMAL_TEXT',
      spaceAbove: 0,
      spaceBelow: 8,
      lineSpacing: 115,
    },
    list: {
      namedStyleType: 'NORMAL_TEXT',
      spaceAbove: 0,
      spaceBelow: 4,
      lineSpacing: 115,
    },
    table: {
      namedStyleType: 'NORMAL_TEXT',
      spaceAbove: 0,
      spaceBelow: 2,
      lineSpacing: 100,
    },
  },
  documentStyle: {
    pageSize: {
      width: pt(595.3),
      height: pt(841.9),
    },
    marginTop: pt(72),
    marginRight: pt(72),
    marginBottom: pt(72),
    marginLeft: pt(72),
  },
};

const HEADING_BY_LEVEL = {
  1: 'heading1',
  2: 'heading2',
  3: 'heading3',
};

class GoogleDocBuilder {
  constructor() {
    this.reset();
  }

  reset() {
    this.requests = [];
    this.tableJobs = [];
    this.index = 1;
  }

  _normalizeText(value) {
    if (value === null || value === undefined) return '';
    if (Array.isArray(value)) {
      return value.map((item) => this._normalizeText(item)).filter(Boolean).join(', ');
    }
    if (typeof value === 'object') {
      return Object.entries(value)
        .filter(([, entryValue]) => entryValue !== null && entryValue !== undefined && entryValue !== '')
        .map(([key, entryValue]) => `${this._humanizeKey(key)}: ${this._normalizeText(entryValue)}`)
        .join('; ');
    }
    return String(value).trim();
  }

  _humanizeKey(key) {
    return String(key)
      .replace(/_/g, ' ')
      .replace(/\b\w/g, (char) => char.toUpperCase());
  }

  _splitParagraphs(text) {
    return this._normalizeText(text)
      .split(/\r?\n+/)
      .map((item) => item.trim())
      .filter(Boolean);
  }

  _insertText(text) {
    const start = this.index;
    this.requests.push({
      insertText: { location: { index: this.index }, text },
    });
    this.index += text.length;
    return { start, end: this.index };
  }

  _insertParagraph(text) {
    const range = this._insertText(`${text}\n`);
    return {
      start: range.start,
      textEnd: range.end - 1,
      end: range.end,
    };
  }

  _styleRange(start, end, style = {}) {
    const textStyle = {};
    const fields = [];

    if (style.bold !== undefined) {
      textStyle.bold = style.bold;
      fields.push('bold');
    }
    if (style.italic !== undefined) {
      textStyle.italic = style.italic;
      fields.push('italic');
    }
    if (style.fontSize) {
      textStyle.fontSize = pt(style.fontSize);
      fields.push('fontSize');
    }
    if (style.foregroundColor) {
      textStyle.foregroundColor = {
        color: { rgbColor: style.foregroundColor },
      };
      fields.push('foregroundColor');
    }

    textStyle.weightedFontFamily = { fontFamily: TEMPLATE.fontFamily };
    fields.push('weightedFontFamily');

    if (fields.length === 0 || end <= start) return;

    this.requests.push({
      updateTextStyle: {
        range: { startIndex: start, endIndex: end },
        textStyle,
        fields: fields.join(','),
      },
    });
  }

  _paragraphStyleRange(start, end, style = {}) {
    const paragraphStyle = {};
    const fields = [];

    if (style.namedStyleType) {
      paragraphStyle.namedStyleType = style.namedStyleType;
      fields.push('namedStyleType');
    }
    if (style.alignment) {
      paragraphStyle.alignment = style.alignment;
      fields.push('alignment');
    }
    if (style.spaceAbove !== undefined) {
      paragraphStyle.spaceAbove = pt(style.spaceAbove);
      fields.push('spaceAbove');
    }
    if (style.spaceBelow !== undefined) {
      paragraphStyle.spaceBelow = pt(style.spaceBelow);
      fields.push('spaceBelow');
    }
    if (style.lineSpacing !== undefined) {
      paragraphStyle.lineSpacing = style.lineSpacing;
      fields.push('lineSpacing');
    }
    if (style.keepWithNext !== undefined) {
      paragraphStyle.keepWithNext = style.keepWithNext;
      fields.push('keepWithNext');
    }

    if (fields.length === 0 || end <= start) return;

    this.requests.push({
      updateParagraphStyle: {
        range: { startIndex: start, endIndex: end },
        paragraphStyle,
        fields: fields.join(','),
      },
    });
  }

  _applyRole(range, role) {
    this._styleRange(range.start, range.textEnd, TEMPLATE.textStyles[role]);
    this._paragraphStyleRange(range.start, range.end, TEMPLATE.paragraphStyles[role]);
  }

  _applyDocumentStyle() {
    this.requests.push({
      updateDocumentStyle: {
        documentStyle: TEMPLATE.documentStyle,
        fields: 'pageSize,marginTop,marginRight,marginBottom,marginLeft',
      },
    });
  }

  _strongPrefixLength(text) {
    const requirementMatch = text.match(/^\[[A-Z]{1,5}-\d{3,}\][^:]{1,120}:/);
    if (requirementMatch) return requirementMatch[0].length;

    const colonIndex = text.indexOf(':');
    if (colonIndex > 0 && colonIndex <= 90) return colonIndex + 1;

    return 0;
  }

  addTitle(text) {
    const value = this._normalizeText(text || 'Documento');
    const range = this._insertParagraph(value);
    this._applyRole(range, 'title');
  }

  addHeading(text, level = 1) {
    const value = this._normalizeText(text);
    if (!value) return;

    const role = HEADING_BY_LEVEL[Math.min(Math.max(Number(level) || 1, 1), 3)];
    const range = this._insertParagraph(value);
    this._applyRole(range, role);
  }

  addParagraph(text) {
    this._splitParagraphs(text).forEach((paragraph) => {
      const range = this._insertParagraph(paragraph);
      this._applyRole(range, 'body');
    });
  }

  addLabelValue(label, value) {
    const normalizedValue = this._normalizeText(value);
    if (!normalizedValue) return;

    const text = `${label}: ${normalizedValue}`;
    const range = this._insertParagraph(text);
    this._applyRole(range, 'body');
    this._styleRange(range.start, range.start + label.length + 1, TEMPLATE.textStyles.label);
  }

  addBulletList(items = []) {
    const normalizedItems = items
      .map((item) => this._normalizeText(item))
      .filter(Boolean);

    if (!normalizedItems.length) return;

    const listStart = this.index;

    normalizedItems.forEach((item) => {
      const range = this._insertParagraph(item);
      this._applyRole(range, 'list');

      const strongPrefixLength = this._strongPrefixLength(item);
      if (strongPrefixLength > 0) {
        this._styleRange(range.start, range.start + strongPrefixLength, TEMPLATE.textStyles.label);
      }
    });

    const listEnd = this.index;
    this.requests.push({
      createParagraphBullets: {
        range: { startIndex: listStart, endIndex: listEnd },
        bulletPreset: 'BULLET_DISC_CIRCLE_SQUARE',
      },
    });
  }

  addTable({ titulo, cabecalhos = [], linhas = [] }) {
    if (titulo) this.addHeading(titulo, 3);
    if (!Array.isArray(cabecalhos) || !cabecalhos.length) return;

    const normalizedHeaders = cabecalhos.map((cell) => this._normalizeText(cell));
    const normalizedRows = (Array.isArray(linhas) ? linhas : []).map((row) => {
      const cells = Array.isArray(row) ? row : [row];
      return cells.map((cell) => this._normalizeText(cell));
    });

    const columnCount = Math.max(
      normalizedHeaders.length,
      ...normalizedRows.map((row) => row.length),
      1
    );

    const marker = `[[TABLE_${this.tableJobs.length}]]`;
    const markerRange = this._insertParagraph(marker);
    this._applyRole(markerRange, 'table');

    this.tableJobs.push({
      marker,
      markerStart: markerRange.start,
      markerEnd: markerRange.textEnd,
      columnCount,
      rows: [
        normalizedHeaders,
        ...normalizedRows,
      ].map((row) => Array.from({ length: columnCount }, (_, index) => row[index] || '')),
    });
  }

  addSection(section, depth = 0) {
    if (!section) return;

    const level = Math.min(Number(section.nivel) || depth + 1, 3);
    if (section.titulo) this.addHeading(section.titulo, level);
    if (section.conteudo) this.addParagraph(section.conteudo);
    if (Array.isArray(section.itens) && section.itens.length) {
      this.addBulletList(section.itens);
    }

    (section.subsecoes || []).forEach((subsection) => this.addSection(subsection, depth + 1));
  }

  addMetadata(doc) {
    const metadata = doc.metadata || {};
    const rows = [
      ['Projeto', metadata.projeto],
      ['Tipo', doc.tipo_documento],
      ['Versão', doc.versao || '1.0'],
      ['Autor', metadata.autor],
      ['Objetivo', metadata.objetivo],
    ].filter(([, value]) => this._normalizeText(value));

    if (!rows.length) return;

    this.addHeading('Informações do Documento', 2);
    rows.forEach(([label, value]) => this.addLabelValue(label, value));
  }

  buildFromDocumentJson(doc = {}) {
    this.reset();
    this._applyDocumentStyle();

    this.addTitle(doc.titulo || 'Documento');
    this.addMetadata(doc);

    if (doc.sumario_executivo) {
      this.addHeading('Sumário Executivo', 1);
      this.addParagraph(doc.sumario_executivo);
    }

    (doc.secoes || []).forEach((section) => this.addSection(section));
    (doc.tabelas || []).forEach((table) => this.addTable(table));

    if (doc.conclusao) {
      this.addHeading('Conclusão', 1);
      this.addParagraph(doc.conclusao);
    }

    return this.requests;
  }

  getTableJobs() {
    return this.tableJobs;
  }
}

module.exports = { GoogleDocBuilder };
