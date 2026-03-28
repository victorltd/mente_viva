// lib/config/constants/legal_constants.dart

class LegalConstants {
  // ══════════════════════════════════════
  // VERSÕES
  // ══════════════════════════════════════
  static const String termsVersion = '1.0.0';
  static const String privacyVersion = '1.0.0';
  static const String lastUpdated = '15 de Janeiro de 2025';

  // ══════════════════════════════════════
  // INFORMAÇÕES DA EMPRESA
  // ══════════════════════════════════════
  static const String companyName = 'MenteViva';
  static const String companyEmail = 'contato@menteviva.app';
  static const String dpoEmail = 'privacidade@menteviva.app';
  static const String supportEmail = 'suporte@menteviva.app';

  // ══════════════════════════════════════
  // DISCLAIMERS
  // ══════════════════════════════════════
  static const String appDisclaimer = 
    'O MenteViva é uma ferramenta de apoio ao acompanhamento terapêutico e '
    'NÃO substitui o atendimento psicológico presencial, consultas médicas '
    'ou tratamento de emergência em saúde mental.';

  static const String emergencyNotice = 
    'Se você está em crise, pensando em se machucar ou precisa de ajuda '
    'urgente, ligue agora para o CVV: 188 (24 horas, gratuito) ou acesse '
    'www.cvv.org.br para chat.';

  static const String emergencyShort = 
    'Em crise? Ligue 188 (CVV) - 24h, gratuito';

  static const String confidentialityNotice = 
    'Suas informações são confidenciais e protegidas por sigilo profissional. '
    'Apenas você e seu psicólogo responsável terão acesso aos seus registros.';

  static const String dataSecurityNotice = 
    'Seus dados são armazenados de forma segura com criptografia e você pode '
    'solicitar acesso, correção ou exclusão a qualquer momento.';

  // ══════════════════════════════════════
  // CFP (Conselho Federal de Psicologia)
  // ══════════════════════════════════════
  static const String cfpNotice = 
    'Este aplicativo segue as diretrizes da Resolução CFP nº 11/2018, que '
    'regulamenta a prestação de serviços psicológicos realizados por meios '
    'de tecnologias da informação e da comunicação.';

  static const String cfpPsychologistNotice = 
    'Ao utilizar este aplicativo para atendimento de pacientes, você declara '
    'estar regularmente inscrito no Conselho Regional de Psicologia (CRP) e '
    'possuir cadastro ativo no e-Psi para prestação de serviços online, '
    'conforme Resolução CFP nº 11/2018.';

  static const String cfpLimitations = 
    'O atendimento psicológico mediado por tecnologia possui limitações e '
    'não é indicado para todas as situações clínicas. Casos de crise, risco '
    'de suicídio ou emergências psiquiátricas devem ser encaminhados para '
    'atendimento presencial ou serviços de emergência.';

  // ══════════════════════════════════════
  // LGPD
  // ══════════════════════════════════════
  static const String lgpdBasis = 
    'O tratamento dos seus dados pessoais é realizado com base no seu '
    'consentimento (Art. 7º, I da LGPD) e para execução de contrato '
    '(Art. 7º, V da LGPD).';

  static const String lgpdRights = 
    'Você tem direito a: acessar seus dados, corrigir informações, '
    'solicitar exclusão, revogar consentimento e portabilidade dos dados.';

  static const String dataRetentionNotice = 
    'Seus dados serão mantidos enquanto você utilizar o serviço. Após '
    'solicitação de exclusão, os dados serão anonimizados em até 30 dias, '
    'exceto quando houver obrigação legal de retenção.';

  // ══════════════════════════════════════
  // CONSENTIMENTOS ESPECÍFICOS
  // ══════════════════════════════════════
  static const String checkinConsent = 
    'Ao realizar check-ins, você autoriza o compartilhamento dessas '
    'informações com seu psicólogo para acompanhamento do tratamento.';

  static const String taskConsent = 
    'As tarefas terapêuticas e suas respostas serão visíveis apenas para '
    'você e seu psicólogo responsável.';

  // ══════════════════════════════════════
  // TERMOS DE USO (RESUMO)
  // ══════════════════════════════════════
  static const List<String> termsHighlights = [
    'O app é uma ferramenta de apoio, não substitui atendimento presencial',
    'Não é um serviço de emergência - em crise, ligue 188 (CVV)',
    'Seus dados são confidenciais e protegidos',
    'Você pode solicitar exclusão dos seus dados a qualquer momento',
    'O psicólogo é responsável pelo tratamento e conduta profissional',
  ];

  // ══════════════════════════════════════
  // POLÍTICA DE PRIVACIDADE (RESUMO)
  // ══════════════════════════════════════
  static const List<String> privacyHighlights = [
    'Coletamos apenas dados necessários para o serviço',
    'Seus dados são criptografados e armazenados com segurança',
    'Compartilhamos dados apenas com seu psicólogo',
    'Não vendemos seus dados para terceiros',
    'Você pode exportar ou excluir seus dados',
  ];
}