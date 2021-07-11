/*
 	Projeto Final de Labort�rio de Banco de Dados (SCC0541 2021/1)
 		Pedro Fernando Christofoletti dos Santos - 11218560
   		Vin�cius Gon�alves de Carvalho - 8517157
 */

-- ATIVIDADE 1a

-- Query original, dada no enunciado da Atividade 1
SELECT * FROM exames ex
JOIN pacientes p ON p.id_paciente = ex.id_paciente
JOIN desfechos d ON p.id_paciente = d.id_paciente
WHERE ex.de_origem = 'Unidades de Interna��o';

-- Query original, alterada para trazer apenas os 20 primeiros resultados, organizadas em ordem crescente por id_exame
SELECT * FROM exames ex
JOIN pacientes p ON p.id_paciente = ex.id_paciente
JOIN desfechos d ON p.id_paciente = d.id_paciente
WHERE ex.de_origem = 'Unidades de Interna��o'
ORDER BY id_exame 
LIMIT 20;

-- An�lise da query original, contendo os tempos
EXPLAIN ANALYZE
SELECT * FROM exames ex
JOIN pacientes p ON p.id_paciente = ex.id_paciente
JOIN desfechos d ON p.id_paciente = d.id_paciente
WHERE ex.de_origem = 'Unidades de Interna��o';

-- Cria��o de �ndice para exames.de_origem
CREATE INDEX origExUnidIntern ON exames(id_exame)
	WHERE de_origem = 'Unidades de Interna��o';

/*

CREATE INDEX origExUnidIntern ON exames(de_origem)
	WHERE de_origem = 'Unidades de Interna��o';

CREATE INDEX origExUnidIntern ON exames USING HASH (de_origem);

CREATE INDEX origExUnidIntern ON exames(id_exame, id_paciente, id_atendimento)
	WHERE de_origem = 'Unidades de Interna��o';

CREATE INDEX idExPacAtd ON exames(id_exame, id_paciente, id_atendimento);

DROP INDEX origExUnidIntern;

DROP INDEX idExPacAtd;
*/

