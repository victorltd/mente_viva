// lib/features/legal/screens/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../config/constants/legal_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Política de Privacidade',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Versão ${LegalConstants.privacyVersion} • '
              'Atualizado em ${LegalConstants.lastUpdated}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: AppSizes.md),

            // LGPD Badge
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.success),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      'Em conformidade com a Lei Geral de Proteção de Dados '
                      '(LGPD - Lei nº 13.709/2018)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            _buildSection(
              context,
              title: '1. Introdução',
              content:
                  'Esta Política de Privacidade descreve como o MenteViva coleta, '
                  'usa, armazena e protege suas informações pessoais. Ao usar '
                  'nosso aplicativo, você concorda com as práticas descritas '
                  'neste documento.',
            ),

            _buildSection(
              context,
              title: '2. Dados que Coletamos',
              content:
                  'Coletamos os seguintes tipos de dados:\n\n'
                  '• Dados de Cadastro: Nome, e-mail, senha\n'
                  '• Dados de Saúde: Check-ins emocionais, humor, energia, sono\n'
                  '• Dados Terapêuticos: Tarefas e respostas, anotações\n'
                  '• Dados Profissionais (Psicólogos): CRP, abordagem\n'
                  '• Dados de Uso: Acessos, funcionalidades utilizadas',
            ),

            _buildSection(
              context,
              title: '3. Como Usamos seus Dados',
              content:
                  'Utilizamos seus dados para:\n\n'
                  '• Fornecer e melhorar nossos serviços\n'
                  '• Permitir o acompanhamento terapêutico pelo seu psicólogo\n'
                  '• Gerar insights sobre sua evolução emocional\n'
                  '• Enviar notificações relevantes ao tratamento\n'
                  '• Cumprir obrigações legais\n'
                  '• Garantir segurança da plataforma',
            ),

            _buildSection(
              context,
              title: '4. Base Legal (LGPD)',
              content:
                  'O tratamento dos seus dados é baseado em:\n\n'
                  '• Consentimento (Art. 7º, I): Para coleta de dados de saúde, '
                  'mediante aceite expresso no cadastro.\n\n'
                  '• Execução de Contrato (Art. 7º, V): Para prestação do serviço '
                  'contratado entre você e a plataforma.\n\n'
                  '• Cumprimento de Obrigação Legal (Art. 7º, II): Quando exigido '
                  'por lei ou regulamentação.',
            ),

            _buildSection(
              context,
              title: '5. Compartilhamento de Dados',
              content:
                  'Seus dados são compartilhados apenas:\n\n'
                  '• Com seu psicólogo: Para fins de acompanhamento terapêutico. '
                  'O profissional tem acesso aos seus check-ins, tarefas e respostas.\n\n'
                  '• Prestadores de serviço: Empresas que nos auxiliam na operação '
                  '(hospedagem, infraestrutura), sob contratos de confidencialidade.\n\n'
                  '• Autoridades: Quando exigido por lei ou ordem judicial.\n\n'
                  'NÃO vendemos, alugamos ou comercializamos seus dados pessoais '
                  'para terceiros.',
            ),

            _buildSection(
              context,
              title: '6. Segurança dos Dados',
              content:
                  'Implementamos medidas de segurança para proteger seus dados:\n\n'
                  '• Criptografia em trânsito (HTTPS/TLS)\n'
                  '• Criptografia em repouso no banco de dados\n'
                  '• Controle de acesso baseado em funções (RLS)\n'
                  '• Autenticação segura\n'
                  '• Backups regulares\n'
                  '• Monitoramento de segurança\n\n'
                  'Apesar de nossos esforços, nenhum sistema é 100% seguro. '
                  'Caso ocorra algum incidente, você será notificado conforme '
                  'exigido pela LGPD.',
            ),

            _buildSection(
              context,
              title: '7. Retenção de Dados',
              content:
                  '${LegalConstants.dataRetentionNotice}\n\n'
                  'Dados clínicos podem ser mantidos por período maior quando '
                  'exigido por regulamentações de saúde ou para defesa em '
                  'processos judiciais.',
            ),

            _buildSection(
              context,
              title: '8. Seus Direitos (LGPD)',
              content:
                  'Você tem os seguintes direitos:\n\n'
                  '• Confirmação: Saber se tratamos seus dados\n'
                  '• Acesso: Obter cópia dos seus dados\n'
                  '• Correção: Corrigir dados incompletos ou incorretos\n'
                  '• Anonimização: Solicitar anonimização de dados desnecessários\n'
                  '• Portabilidade: Receber seus dados em formato estruturado\n'
                  '• Eliminação: Solicitar exclusão dos dados\n'
                  '• Revogação: Retirar seu consentimento a qualquer momento\n'
                  '• Informação: Saber com quem compartilhamos seus dados\n\n'
                  'Para exercer seus direitos, acesse as Configurações do app '
                  'ou entre em contato pelo e-mail ${LegalConstants.dpoEmail}',
            ),

            _buildSection(
              context,
              title: '9. Dados Sensíveis',
              content:
                  'Os dados de saúde coletados (humor, emoções, informações '
                  'terapêuticas) são considerados dados sensíveis pela LGPD.\n\n'
                  'O tratamento desses dados é feito exclusivamente:\n'
                  '• Com seu consentimento expresso\n'
                  '• Para fins de acompanhamento de saúde\n'
                  '• Com acesso restrito ao seu psicólogo\n'
                  '• Sob proteção de sigilo profissional',
            ),

            _buildSection(
              context,
              title: '10. Transferência Internacional',
              content:
                  'Nossos servidores estão localizados em centros de dados '
                  'seguros. Caso haja transferência internacional de dados, '
                  'garantimos que será feita em conformidade com a LGPD, '
                  'utilizando cláusulas contratuais padrão ou outros mecanismos '
                  'legalmente previstos.',
            ),

            _buildSection(
              context,
              title: '11. Menores de Idade',
              content:
                  'O MenteViva pode ser utilizado por menores de 18 anos apenas '
                  'com consentimento dos pais ou responsáveis legais. O psicólogo '
                  'é responsável por verificar essa condição antes de incluir '
                  'pacientes menores na plataforma.',
            ),

            _buildSection(
              context,
              title: '12. Alterações nesta Política',
              content:
                  'Podemos atualizar esta Política periodicamente. Você será '
                  'notificado sobre alterações significativas e precisará '
                  'aceitar a nova versão para continuar usando o serviço.\n\n'
                  'Recomendamos revisar esta página regularmente.',
            ),

            _buildSection(
              context,
              title: '13. Encarregado de Dados (DPO)',
              content:
                  'Para questões relacionadas à proteção de dados:\n\n'
                  '📧 E-mail: ${LegalConstants.dpoEmail}\n\n'
                  'Você também pode registrar reclamações junto à Autoridade '
                  'Nacional de Proteção de Dados (ANPD).',
            ),

            _buildSection(
              context,
              title: '14. Contato',
              content:
                  'Para dúvidas gerais sobre esta Política:\n\n'
                  '📧 ${LegalConstants.companyEmail}\n'
                  '📧 ${LegalConstants.supportEmail}',
            ),

            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}