import type { Metadata, Viewport } from 'next'
import { Source_Sans_3, Playfair_Display, JetBrains_Mono } from 'next/font/google'

import './globals.css'

const _sourceSans = Source_Sans_3({ subsets: ['latin'], variable: '--font-source-sans' })
const _playfair = Playfair_Display({ subsets: ['latin'], variable: '--font-playfair' })
const _jetbrains = JetBrains_Mono({ subsets: ['latin'], variable: '--font-jetbrains' })

export const metadata: Metadata = {
  title: 'SnapVault - Photo Album Style Guide',
  description: 'A photo album webapp mockup using DaisyUI, Tailwind, and Chelekom-inspired patterns',
}

export const viewport: Viewport = {
  themeColor: '#2d3a2e',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" data-theme="light">
      <body className={`${_sourceSans.variable} ${_playfair.variable} ${_jetbrains.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  )
}
