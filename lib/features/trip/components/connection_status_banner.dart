import 'package:flutter/material.dart';

import '../../../core/models/connection_state.dart';

/// Redesigned ConnectionStatusBanner.
///
/// It is rendered as a thin, highly polished, color-coded status strip
/// at the top of the Trip Screen body.
class ConnectionStatusBanner extends StatelessWidget {
  final ConnectionStateModel connectionState;
  final int? queuedCount;
  final bool hasUnsyncedItems;
  final bool canAddConnectedGuest;
  final VoidCallback onManageConnection;
  final VoidCallback onAddConnectedGuest;

  const ConnectionStatusBanner({
    super.key,
    required this.connectionState,
    required this.queuedCount,
    required this.hasUnsyncedItems,
    required this.canAddConnectedGuest,
    required this.onManageConnection,
    required this.onAddConnectedGuest,
  });

  @override
  Widget build(BuildContext context) {
    // Return empty if inactive or idle
    if (connectionState.status == ConnectionStatus.idle &&
        connectionState.role == ConnectionRole.idle &&
        !hasUnsyncedItems) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine status color and text based on connection state.
    Color statusColor = colorScheme.outline;
    String statusText = 'Offline';
    IconData statusIcon = Icons.offline_bolt_outlined;
    bool isProcessing = false;

    switch (connectionState.status) {
      case ConnectionStatus.idle:
        if (hasUnsyncedItems) {
          statusColor = const Color(0xFFFBBF24); // Amber
          statusText = 'Unsynced items queued';
          statusIcon = Icons.cloud_queue;
        }
        break;
      case ConnectionStatus.checkingPermissions:
      case ConnectionStatus.requestSent:
      case ConnectionStatus.awaitingConfirmation:
        statusColor = const Color(0xFFFBBF24); // Amber
        statusText = 'Connecting...';
        statusIcon = Icons.hourglass_empty;
        isProcessing = true;
        break;
      case ConnectionStatus.advertising:
        statusColor = colorScheme.primary; // Electric Purple
        statusText = 'Hosting lobby...';
        statusIcon = Icons.radar;
        isProcessing = true;
        break;
      case ConnectionStatus.discovering:
        statusColor = colorScheme.secondary; // Electric Blue / Cyan
        statusText = 'Scanning for host...';
        statusIcon = Icons.wifi_tethering;
        isProcessing = true;
        break;
      case ConnectionStatus.connected:
        statusColor = const Color(0xFF4ADE80); // Green
        final peer = connectionState.selectedDevice?.displayName ?? 'Peer';
        statusText = 'Connected to $peer';
        statusIcon = Icons.circle; // Will be rendered custom pulsing dot
        break;
      case ConnectionStatus.requestIncoming:
        statusColor = const Color(0xFFFBBF24); // Amber
        statusText = 'Connection requested';
        statusIcon = Icons.contact_page_outlined;
        break;
      case ConnectionStatus.disconnected:
        statusColor = colorScheme.error;
        statusText = 'Connection lost';
        statusIcon = Icons.signal_wifi_off;
        break;
      case ConnectionStatus.error:
      case ConnectionStatus.permissionDenied:
        statusColor = colorScheme.error;
        statusText = 'Connection error';
        statusIcon = Icons.error_outline;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Pulse or Spinner or Icon
          if (isProcessing)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            )
          else if (connectionState.status == ConnectionStatus.connected)
            _PulsingDot(color: statusColor)
          else
            Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 10),

          // Label
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    statusText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (queuedCount != null && queuedCount! > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$queuedCount queued',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Thin Actions
          if (canAddConnectedGuest) ...[
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onAddConnectedGuest,
              child: Text(
                'Add Guest',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: Icon(Icons.settings, color: statusColor, size: 18),
            onPressed: onManageConnection,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

/// Helper widget to render a pulsing connected green dot.
class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * _controller.value),
                blurRadius: 6 * _controller.value,
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
