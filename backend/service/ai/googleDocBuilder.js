class GoogleDocBuilder {
  constructor() {
    this.requests = [];
    this.index = 1;
  }

  _insertText(text) {
    const start = this.index;
    this.requests.push({
      insertText: { location: { index: this.index }, text },
    });
    this.index += text.length;
    return { start, end: this.index };
  }

  _styleRange(start, end, style) {
    const textStyle = {};
    const fields = [];

    if (style.bold) {
      textStyle.bold = true;
      fields.push('bold');
    }
    if (style.italic) {
      textStyle.italic = true;
      fields.push('italic');
    }
    if (style.fontSize) {
      textStyle.fontSize = { magnitude: style.fontSize, unit: 'PT' };
      fields.push('fontSize');
    }
    if (style.foregroundColor) {
      textStyle.foregroundColor = {
        color: { rgbColor: style.foregroundColor },
      };
      fields.push('foregroundColor');
    }

    if (fields.length === 0 || end <= start) return;

    this.requests.push({
      updateTextStyle: {
        range: { startIndex: start, endIndex: end },
        textStyle,
        fields: fields.join(','),
      },
    });
  }

  addEmptyLine() {
    this._insertText('\n');
  }

  addTitle(text) {
    const range = this._insertText(`${text}\n`);
    this._styleRange(range.start, range.end - 1, { bold: true, fontSize: 20 });
    this.addEmptyLine();
  }

  addHeading(text, level = 1) {
    const sizes = { 1: 16, 2: 14, 3: 12 };
    const range = this._insertText(`${text}\n`);
    this._styleRange(range.start, range.end - 1, {
      bold: true,
      fontSize: sizes[level] || 12,
    });
    this.addEmptyLine();
  }

  addParagraph(text) {
    if (!text) return;
    this._insertText(`${text}\n\n`);
  }

  addLabelValue(label, value) {
    if (!value) return;
    const labelRange = this._insertText(`${label}: `);
    this._styleRange(labelRange.start, labelRange.end - 2, { bold: true });
    this._insertText(`${value}\n`);
  }

  addBulletList(items = []) {
    items.filter(Boolean).forEach((item) => {
      const range = this._insertText(`• ${item}\n`);
      this._styleRange(range.start, range.start + 1, { bold: true });
    });
    this.addEmptyLine();
  }

  addTable({ titulo, cabecalhos = [], linhas = [] }) {
    if (titulo) this.addHeading(titulo, 3);
    if (!cabecalhos.length) return;

    const rows = [cabecalhos, ...linhas];
    rows.forEach((row, rowIndex) => {
      const line = row.map((cell) => String(cell ?? '')).join('  |  ');
      const range = this._insertText(`${line}\n`);
      if (rowIndex === 0) {
        this._styleRange(range.start, range.end - 1, { bold: true });
      }
    });
    this.addEmptyLine();
  }

  addSection(section, depth = 0) {
    if (!section) return;

    const level = Math.min((section.nivel || depth + 1), 3);
    if (section.titulo) this.addHeading(section.titulo, level);
    if (section.conteudo) this.addParagraph(section.conteudo);
    if (Array.isArray(section.itens) && section.itens.length) {
      this.addBulletList(section.itens);
    }

    (section.subsecoes || []).forEach((sub) => this.addSection(sub, depth + 1));
  }

  buildFromDocumentJson(doc) {
    this.addTitle(doc.titulo || 'Documento');

    if (doc.metadata) {
      this.addHeading('Informações do Documento', 2);
      this.addLabelValue('Projeto', doc.metadata.projeto);
      this.addLabelValue('Tipo', doc.tipo_documento);
      this.addLabelValue('Versão', doc.versao || '1.0');
      this.addLabelValue('Autor', doc.metadata.autor);
      this.addLabelValue('Objetivo', doc.metadata.objetivo);
      this.addEmptyLine();
    }

    if (doc.sumario_executivo) {
      this.addHeading('Sumário Executivo', 1);
      this.addParagraph(doc.sumario_executivo);
    }

    (doc.secoes || []).forEach((secao) => this.addSection(secao));

    (doc.tabelas || []).forEach((tabela) => this.addTable(tabela));

    if (doc.conclusao) {
      this.addHeading('Conclusão', 1);
      this.addParagraph(doc.conclusao);
    }

    return this.requests;
  }
}

module.exports = { GoogleDocBuilder };
