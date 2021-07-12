/****** Questão 1 ******/
/* OBS: Colher tempo de execução e as 20 primeiras tuplas para cada consulta */

/* 	Parte 1: consulta frequente disponibilizada */
SELECT * FROM exames ex
	JOIN pacientes p ON p . id_paciente = ex . id_paciente
	JOIN desfechos d ON p . id_paciente = d . id_paciente
	WHERE ex . de_origem = 'Unidades de Internação'
	LIMIT 20;

EXPLAIN ANALYZE
	SELECT * FROM exames ex
		JOIN pacientes p ON p . id_paciente = ex . id_paciente
		JOIN desfechos d ON p . id_paciente = d . id_paciente
		WHERE ex . de_origem = 'Unidades de Internação';
	
/* Parte 2: consulta frequente disponibilizada com uso de índices */

/* Parte 3: consulta frequente proposta */

/* Parte 4: consulta frequente proposta com uso de índices */

/* 
	RELATÓRIO: Justificar a consulta criada e a implementação do índice de acordo com a consulta, explicitando o
	porquê do índice otimizar tal consulta, conforme visto durante as aulas.
*/

/****** Questão 2 ******/

/* 	Parte 1: rotina para criar senha automática para novos pacientes que serão inseridos na base */

/* 	Parte 2: criar tabela LogAcesso (data/hora, tipo de operação e tabela requisitada/alterada) */

/* 	Parte 3: rotina para criar logs na tabela LogAcesso quando os acessos e transações são realizados na base de dados
OBS: deve analisar três situações pertinentes para realizar a coleta da informação automaticamente */

/* 
	RELATÓRIO: as situações devem ser devidamente registradas e validadas por meios
	de testes, além de serem sucintamente explicadas, em relação a semântica da
	operação e relevância para o sistema em si.
*/

/****** Questão 3 ******/

/* 	Parte 1: Que tipo de informações relacionadas a COVID é possível recuperar analisando
os tipos de exames e analitos registrados? */

/* 	Parte 2: Analisando a quantidade de registros de um determinado exame de COVID em
relação a data de coleta ou período (por exemplo semanal), é possível indicar tendências de alta
e/ou baixa que auxiliariam a especialistas médicos em analises futuras? */

/* 	Parte 3: Que tipo de informações adicionais, em versões futuras da base de dados, poderiam
ser coletadas em novos hospitais para melhorar a qualidade dos dados analisados? */

/* 
	RELATÓRIO: é necessário realizar uma análise exploratória nos dados, selecionando informações relevantes
	com base em algum critério pertinente, justificando sua relevância no auxílio a especialistas.
*/