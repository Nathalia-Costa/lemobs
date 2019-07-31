SELECT DISTINCT
	"requisicao"."id", 
    Array_agg(DISTINCT( historico_solicitacao.solicitacao_id )) AS "solicitacoes", 
	"requisicao"."numero"                                       AS "numero", 
	"requisicao"."data_execucao"                                AS "data_requisicao", 
	"regional"."nome"                                           AS "regional_nome", 
	"area"."id"                                                 AS "area_id", 
	"area"."nome"                                               AS "area_nome", 
	"regional"."id"                                             AS "regional_id", 
	(
		SELECT
			Count(DISTINCT "historico"."solicitacao_id") AS "num_solicitacoes" 
		FROM  
			"atende"."historico_solicitacao" AS "historico" 
		INNER JOIN
			"atende"."solicitacao" ON "solicitacao"."id" = "historico"."solicitacao_id" 
		WHERE
			"historico"."requisicao_servico_id" = requisicao.id
	), 
	(
		SELECT
			Count(DISTINCT "historico"."solicitacao_id") AS  "solicitacoes_resolvidas" 
		FROM
			"atende"."historico_solicitacao" AS "historico" 
		INNER JOIN
			"atende"."solicitacao" ON "solicitacao"."id" = "historico"."solicitacao_id" 
		WHERE
			historico.requisicao_servico_id = requisicao.id 
			AND historico.situacao_solicitacao_id IN ( 4, 8, 5, 9 )
	), 
    (
		SELECT
			CASE 
                WHEN
					(
						SELECT
							Count(DISTINCT( solicitacao_id )) 
                        FROM
							atende.historico_solicitacao hs 
                        WHERE
							requisicao.id = requisicao_servico_id 
						   AND situacao_solicitacao_id IN( 4, 8, 5, 9, 3 )
					) = (
						SELECT
							Count(DISTINCT( solicitacao_id )) 
                        FROM
							atende.historico_solicitacao hs 
                        WHERE
							requisicao.id = requisicao_servico_id
					)
				THEN 
                    'Encaminhado' 
                WHEN
					(
						SELECT
							Count(DISTINCT( solicitacao_id )) 
                        FROM
							atende.historico_solicitacao hs 
                        WHERE
							requisicao.id = requisicao_servico_id 
                            AND situacao_solicitacao_id IN ( 4, 8, 5, 9, 3 )
					) > 0 
                THEN 
                    'Parcialmente encaminhado' 
				ELSE
					'Não encaminhado' 
			END AS status
	), 
	(
		SELECT
			(
				Cast(
					Round(
						Cast(
							(
								(
									(
										SELECT
											Count(DISTINCT "historico"."solicitacao_id") AS "solicitacoes_resolvidas" 
										FROM
											"atende"."historico_solicitacao" AS "historico" 
										INNER JOIN
											"atende"."solicitacao" ON "solicitacao"."id" = "historico"."solicitacao_id" 
										WHERE
											historico.requisicao_servico_id = requisicao.id 
											AND historico.situacao_solicitacao_id IN ( 4, 8, 5, 9 )
									) 
									/
										CASE 
											WHEN 
												( 
													SELECT
														Count(DISTINCT "historico"."solicitacao_id") AS "num_solicitacoes" 
													FROM
														"atende"."historico_solicitacao" AS "historico" 
													INNER JOIN
														"atende"."solicitacao" ON "solicitacao"."id" = "historico"."solicitacao_id" 
													WHERE
														"historico"."requisicao_servico_id" = requisicao.id
												) > 0
											THEN 
												( 
													SELECT
														Count(DISTINCT "historico"."solicitacao_id") AS "num_solicitacoes" 
													FROM
														"atende"."historico_solicitacao" AS "historico" 
													INNER JOIN
														"atende"."solicitacao" ON "solicitacao"."id" = "historico"."solicitacao_id" 
													WHERE
														"historico"."requisicao_servico_id" = requisicao.id
												) 
											ELSE
												0.000001 
										END
								) * 100 
							) AS NUMERIC
						)
					, 2) AS TEXT
				) || '%' 
			) AS porcentagem_situacao_resolvida
	), 
	(
		SELECT
			Count(DISTINCT "requisicao_servico"."id") AS "total" 
		FROM
			"atende"."requisicao_servico" 
		INNER JOIN
			"atende"."historico_solicitacao" ON "historico_solicitacao"."requisicao_servico_id" = "requisicao_servico"."id"
	) 
FROM
	"atende"."requisicao_servico" AS "requisicao" 
INNER JOIN
	"atende"."regional" ON "requisicao"."regional_id" = "regional"."id" 
INNER JOIN
	"atende"."area" ON "area"."id" = "regional"."area_id" 
INNER JOIN
	"atende"."historico_solicitacao" ON "historico_solicitacao"."requisicao_servico_id" = "requisicao"."id" 
GROUP  BY
	"requisicao"."id", 
	"requisicao"."numero", 
	"requisicao"."data_execucao", 
	"regional"."nome", 
	"area"."id", 
	"area"."nome", 
	"regional"."id" 