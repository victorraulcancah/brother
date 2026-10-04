/**
 * Logo de BRINTECH Technology Consulting en vector: el monograma VR (trazado del logo
 * original) y el texto en la tipografía de la página. Se dibuja sobre fondo claro, dentro de
 * un círculo de 240x240 (el contenido queda inscrito para que ningún borde se recorte).
 */
export default function LogoBrintech({ className }) {
    return (
        <svg
            viewBox="0 0 240 240"
            className={className}
            role="img"
            aria-label="BRINTECH Technology Consulting"
            fill="none"
        >
            <title>BRINTECH Technology Consulting</title>
            <defs>
                <linearGradient id="brintech-azul" x1="0" y1="0" x2="1" y2="1">
                    <stop offset="0" stopColor="#3b82f6" />
                    <stop offset="1" stopColor="#1d4ed8" />
                </linearGradient>
                <linearGradient id="brintech-gris" x1="0" y1="0" x2="1" y2="1">
                    <stop offset="0" stopColor="#7b808b" />
                    <stop offset="1" stopColor="#363a43" />
                </linearGradient>
            </defs>

            {/* Monograma VR: 192x108 unidades, escalado y centrado arriba */}
            <g transform="translate(46 42) scale(0.79)" fillRule="evenodd">
                <path d="M122.6 74.5 L122.4 75.9 L123.5 77.6 L140.3 95.0 L144.2 98.7 L146.1 99.2 L153.2 99.6 L164.4 99.6 L165.7 99.0 L165.7 98.1 L153.5 83.0 L142.3 70.1 L139.4 67.5 L137.8 67.3 L129.0 71.3 L125.6 72.2 L123.5 73.5ZM150.8 14.4 L146.9 12.6 L143.9 11.8 L138.1 11.5 L117.8 11.6 L116.0 11.8 L114.9 12.4 L112.0 17.1 L110.8 20.1 L108.7 23.5 L108.6 26.2 L109.4 27.4 L139.2 28.2 L141.2 29.2 L143.3 31.2 L144.1 33.0 L144.7 36.2 L144.5 38.9 L143.4 42.2 L142.4 43.9 L140.6 45.5 L138.0 46.9 L134.5 47.2 L133.0 49.5 L131.5 50.3 L122.6 50.8 L119.4 51.5 L118.0 52.5 L113.7 57.2 L112.1 60.0 L110.2 62.0 L110.0 63.1 L110.8 64.4 L116.9 70.3 L118.1 70.5 L122.4 69.0 L133.6 63.7 L134.5 62.6 L134.2 60.6 L135.0 59.8 L142.1 58.3 L148.1 55.9 L153.2 52.1 L156.6 48.8 L158.4 46.2 L160.5 41.6 L161.6 35.9 L161.6 33.4 L160.5 27.1 L158.6 22.5 L157.3 20.4 L154.5 17.3Z" fill="url(#brintech-gris)" />
                <path d="M113.4 11.8 L112.2 11.3 L110.2 11.1 L95.8 11.3 L93.8 12.1 L91.6 14.5 L77.1 35.8 L66.8 51.9 L66.7 53.4 L67.5 55.4 L73.5 65.1 L74.6 66.4 L76.1 66.7 L77.7 65.4 L99.0 34.1 L107.6 22.5 L109.5 19.4 L113.0 15.5 L114.1 13.3 L113.9 12.4ZM180.0 21.9 L178.2 18.6 L176.2 16.4 L173.4 14.1 L169.4 12.2 L162.1 9.8 L150.2 9.1 L149.9 9.8 L150.8 10.5 L160.9 12.7 L166.2 15.0 L169.6 17.8 L172.4 21.4 L173.5 24.9 L173.3 30.2 L171.7 35.9 L168.4 42.0 L167.1 42.8 L164.2 43.5 L163.0 44.2 L162.1 45.4 L160.7 48.9 L155.9 52.5 L151.9 55.1 L141.0 61.1 L136.6 63.1 L130.2 65.2 L122.6 69.1 L119.9 69.9 L112.2 73.5 L104.2 76.0 L100.9 77.4 L96.1 78.5 L95.2 78.4 L94.8 77.7 L95.4 76.8 L106.6 64.9 L111.6 60.5 L113.6 57.2 L118.6 51.8 L119.9 51.2 L122.0 50.7 L131.2 50.2 L132.6 49.6 L133.3 48.6 L132.6 47.4 L130.9 46.8 L116.0 46.6 L113.4 47.1 L110.8 49.0 L83.4 76.0 L80.6 78.4 L79.2 78.9 L77.8 78.1 L75.6 75.0 L65.5 57.9 L51.2 35.2 L39.0 14.9 L37.5 12.9 L36.0 11.8 L34.4 11.4 L17.1 11.4 L14.1 11.6 L12.9 12.8 L13.3 14.2 L16.0 17.6 L18.4 21.6 L42.9 57.0 L60.2 83.1 L60.8 84.8 L60.5 85.6 L59.6 86.3 L55.8 87.0 L46.6 87.5 L36.1 87.2 L33.1 86.7 L27.1 84.9 L24.4 83.4 L21.4 81.0 L20.1 79.1 L19.1 75.5 L19.1 73.5 L19.7 70.6 L20.9 67.4 L24.2 62.0 L30.9 54.5 L31.2 53.7 L30.6 53.3 L29.4 53.8 L25.4 56.7 L18.4 63.0 L13.5 69.2 L10.5 74.4 L9.8 76.1 L9.1 81.0 L9.8 84.4 L10.6 86.0 L12.2 87.7 L16.5 91.0 L18.8 92.0 L25.0 93.5 L36.5 94.1 L54.8 92.1 L62.4 90.4 L63.9 90.4 L65.1 91.0 L66.2 92.4 L69.3 98.3 L70.6 99.2 L72.0 99.2 L74.5 97.4 L85.2 86.8 L88.6 84.2 L96.8 81.9 L99.5 80.7 L108.9 77.8 L117.4 74.4 L120.9 73.8 L127.9 70.7 L131.5 70.1 L135.9 68.2 L140.6 64.9 L150.6 60.0 L161.6 53.6 L163.4 53.2 L167.2 53.7 L169.6 52.8 L170.8 51.6 L171.7 50.0 L171.9 48.5 L171.7 46.1 L172.0 45.0 L177.4 37.9 L179.9 32.6 L180.6 27.2Z" fill="url(#brintech-azul)" />
            </g>

            <text
                x="120"
                y="168"
                textAnchor="middle"
                fontSize="25"
                fontWeight="800"
                letterSpacing="3.6"
                fill="#2563eb"
                style={{ fontFamily: "'Manrope', ui-sans-serif, system-ui, sans-serif" }}
            >
                BRINTECH
            </text>
            <path d="M40 186h22M178 186h22" stroke="#2563eb" strokeWidth="1.2" strokeLinecap="round" />
            <text
                x="120"
                y="189"
                textAnchor="middle"
                fontSize="7.4"
                fontWeight="600"
                letterSpacing="2.1"
                fill="#475569"
                style={{ fontFamily: "'Manrope', ui-sans-serif, system-ui, sans-serif" }}
            >
                TECHNOLOGY CONSULTING
            </text>
        </svg>
    );
}
