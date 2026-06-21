import React from 'react';
import { CheckCircle2, AlertTriangle, XCircle, HelpCircle, ShieldAlert } from 'lucide-react';

/**
 * ComplianceBadge Component.
 * Receives a score or status and renders a premium colored pill with appropriate Lucide icons.
 */
export function ComplianceBadge({ score, status }) {
  let badgeStatus = status;
  const finalScore = typeof score === 'number' ? score : parseFloat(score);

  // If status is omitted, classify automatically from score
  if (!badgeStatus && !isNaN(finalScore)) {
    if (finalScore >= 75) {
      badgeStatus = 'Compliant';
    } else if (finalScore >= 40) {
      badgeStatus = 'Partially Compliant';
    } else {
      badgeStatus = 'Non-Compliant';
    }
  }

  // Fallback value
  if (!badgeStatus) {
    badgeStatus = 'Pending';
  }

  // Configuration mapping for colors, labels, and icons
  let config = {
    colorClass: 'bg-gray-100 text-gray-800 border-gray-200',
    icon: HelpCircle,
    label: badgeStatus
  };

  switch (badgeStatus.toLowerCase()) {
    case 'compliant':
      config = {
        colorClass: 'bg-green-50 text-green-700 border-green-200',
        icon: CheckCircle2,
        label: 'Compliant'
      };
      break;
    case 'partially compliant':
      config = {
        colorClass: 'bg-amber-50 text-amber-700 border-amber-200',
        icon: AlertTriangle,
        label: 'Partially Compliant'
      };
      break;
    case 'non-compliant':
      config = {
        colorClass: 'bg-red-50 text-red-700 border-red-200',
        icon: XCircle,
        label: 'Non-Compliant'
      };
      break;
    case 'suspended':
      config = {
        colorClass: 'bg-purple-50 text-purple-700 border-purple-200',
        icon: ShieldAlert,
        label: 'Suspended'
      };
      break;
    case 'pending':
    default:
      config = {
        colorClass: 'bg-blue-50 text-blue-700 border-blue-200',
        icon: HelpCircle,
        label: 'Pending'
      };
      break;
  }

  const IconComponent = config.icon;

  return (
    <span className={`inline-flex items-center gap-1 py-0.5 px-2 rounded-full text-xs font-medium border ${config.colorClass}`}>
      <IconComponent className="w-3.5 h-3.5 shrink-0" />
      <span>{config.label}</span>
    </span>
  );
}

export default ComplianceBadge;
