SELECT * FROM exames ex
JOIN pacientes p ON p.id_paciente = ex.id_paciente
JOIN desfechos d ON p.id_paciente = d.id_paciente
WHERE ex.de_origem = 'Unidades de Internação';