/*
 	Projeto Final de Labortário de Banco de Dados (SCC0541 2021/1)
 		Pedro Fernando Christofoletti dos Santos - 11218560
   		Vinícius Gonçalves de Carvalho - 8517157
 */

-- ATIVIDADE 1a

-- Query original, dada no enunciado da Atividade 1
SELECT * FROM exames ex
JOIN pacientes p ON p.id_paciente = ex.id_paciente
JOIN desfechos d ON p.id_paciente = d.id_paciente
WHERE ex.de_origem = 'Unidades de Internação';

-- Query original, alterada para trazer apenas os 20 primeiros resultados, organizadas em ordem crescente por id_exame
SELECT * FROM exames ex
JOIN pacientes p ON p.id_paciente = ex.id_paciente
JOIN desfechos d ON p.id_paciente = d.id_paciente
WHERE ex.de_origem = 'Unidades de Internação'
ORDER BY id_exame 
LIMIT 20;

-- Análise da query original, contendo os tempos
EXPLAIN ANALYZE
SELECT * FROM exames ex
JOIN pacientes p ON p.id_paciente = ex.id_paciente
JOIN desfechos d ON p.id_paciente = d.id_paciente
WHERE ex.de_origem = 'Unidades de Internação';