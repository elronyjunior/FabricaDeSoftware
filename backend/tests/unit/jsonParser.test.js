const { parseJsonFromAi } = require('../../service/ai/jsonParser');

describe('parseJsonFromAi', () => {
  it('faz parse direto de um JSON válido', () => {
    const resultado = parseJsonFromAi('{"nome": "Projeto X", "valor": 10}');
    expect(resultado).toEqual({ nome: 'Projeto X', valor: 10 });
  });

  it('remove cercas de markdown (```json ... ```)', () => {
    const resultado = parseJsonFromAi('```json\n{"ok": true}\n```');
    expect(resultado).toEqual({ ok: true });
  });

  it('ignora texto antes do JSON', () => {
    const resultado = parseJsonFromAi('Aqui está o JSON solicitado:\n{"a": 1}');
    expect(resultado).toEqual({ a: 1 });
  });

  it('escapa quebras de linha literais dentro de strings', () => {
    const resultado = parseJsonFromAi('{"descricao": "linha 1\nlinha 2"}');
    expect(resultado.descricao).toBe('linha 1\nlinha 2');
  });

  it('repara JSON truncado por max_tokens (string aberta e chaves faltando)', () => {
    const truncado = '{"requisitos": [{"titulo": "Login", "descricao": "texto incompl';
    const resultado = parseJsonFromAi(truncado);
    expect(resultado.requisitos).toHaveLength(1);
    expect(resultado.requisitos[0].titulo).toBe('Login');
  });

  it('repara JSON truncado logo após dois-pontos', () => {
    const truncado = '{"titulo": "Doc", "metadata": ';
    const resultado = parseJsonFromAi(truncado);
    expect(resultado.titulo).toBe('Doc');
    expect(resultado.metadata).toBeNull();
  });

  it('repara JSON truncado com vírgula pendente', () => {
    const truncado = '{"a": 1, "b": 2,';
    const resultado = parseJsonFromAi(truncado);
    expect(resultado).toEqual({ a: 1, b: 2 });
  });

  it('lança erro para conteúdo vazio', () => {
    expect(() => parseJsonFromAi('')).toThrow('Resposta vazia da IA');
  });

  it('lança erro para conteúdo nulo', () => {
    expect(() => parseJsonFromAi(null)).toThrow('Resposta vazia da IA');
  });

  it('lança erro se nem o reparo conseguir produzir JSON válido', () => {
    expect(() => parseJsonFromAi('isto não é json nem de longe')).toThrow(/Falha ao parsear JSON/);
  });
});
