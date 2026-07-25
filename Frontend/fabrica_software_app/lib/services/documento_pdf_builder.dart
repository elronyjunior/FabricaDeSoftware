import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fabrica_software_app/models/documento_conteudo.dart';

double _tamanhoFontePdf(int nivel) {
  switch (nivel < 1 ? 1 : (nivel > 3 ? 3 : nivel)) {
    case 1:
      return 16;
    case 2:
      return 14;
    default:
      return 12;
  }
}

List<pw.Widget> _construirSecaoPdf(SecaoDocumento secao) {
  return [
    pw.SizedBox(height: 10),
    pw.Padding(
      padding: pw.EdgeInsets.only(left: (secao.depth * 12).toDouble()),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            secao.titulo.isEmpty ? 'Sem título' : secao.titulo,
            style: pw.TextStyle(fontSize: _tamanhoFontePdf(secao.nivel), fontWeight: pw.FontWeight.bold),
          ),
          if (secao.conteudo.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(secao.conteudo, style: const pw.TextStyle(fontSize: 11)),
          ],
          if (secao.itens.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ...secao.itens.map((item) => pw.Bullet(text: item, style: const pw.TextStyle(fontSize: 11))),
          ],
        ],
      ),
    ),
    ...secao.subsecoes.expand(_construirSecaoPdf),
  ];
}

pw.Widget _construirTabelaPdf(TabelaDocumento tabela) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12, bottom: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if ((tabela.titulo ?? '').isNotEmpty)
          pw.Text(tabela.titulo!, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headers: tabela.cabecalhos,
          data: tabela.linhas,
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}

// Gera um PDF a partir do JSON estruturado do documento, espelhando a mesma
// hierarquia (título, seções por nível, itens, tabelas, conclusão) usada na
// visualização in-app e no Google Docs.
Future<Uint8List> construirPdfDocumento(DocumentoConteudo documento) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (context) => [
        pw.Text(documento.titulo, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 16),
        if ((documento.sumarioExecutivo ?? '').isNotEmpty) ...[
          pw.Text('Sumário Executivo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(documento.sumarioExecutivo!, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 12),
        ],
        ...documento.secoes.expand(_construirSecaoPdf),
        if (documento.tabelas.isNotEmpty) ...documento.tabelas.map(_construirTabelaPdf),
        if ((documento.conclusao ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Conclusão', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(documento.conclusao!, style: const pw.TextStyle(fontSize: 11)),
        ],
      ],
    ),
  );

  return pdf.save();
}
