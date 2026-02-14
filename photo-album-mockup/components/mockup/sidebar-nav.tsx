"use client"

import {
  Camera,
  ImageIcon,
  FolderOpen,
  Heart,
  Share2,
  Trash2,
  Upload,
  Settings,
  Sun,
  Moon,
  Menu,
  X,
  Tag,
  Clock,
} from "lucide-react"
import { useState, useEffect } from "react"

const navItems = [
  { icon: ImageIcon, label: "All Photos", section: "photos" },
  { icon: FolderOpen, label: "Albums", section: "albums" },
  { icon: Heart, label: "Favorites", section: "favorites" },
  { icon: Share2, label: "Shared", section: "shared" },
  { icon: Clock, label: "Recent", section: "recent" },
  { icon: Tag, label: "Tags", section: "tags" },
  { icon: Upload, label: "Upload", section: "upload" },
  { icon: Trash2, label: "Trash", section: "trash" },
]

export function SidebarNav({
  onNavigate,
  activeSection,
}: {
  onNavigate: (section: string) => void
  activeSection: string
}) {
  const [isDark, setIsDark] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", isDark ? "dark" : "light")
  }, [isDark])

  const handleNav = (section: string) => {
    onNavigate(section)
    setMobileOpen(false)
  }

  return (
    <>
      {/* Mobile top bar */}
      <div className="lg:hidden flex items-center justify-between bg-base-200 border-b border-base-300 px-4 py-3 fixed top-0 left-0 right-0 z-50">
        <button
          className="btn btn-ghost btn-sm btn-square"
          onClick={() => setMobileOpen(true)}
          aria-label="Open menu"
        >
          <Menu className="h-5 w-5" />
        </button>
        <div className="flex items-center gap-2.5">
          <Camera className="h-5 w-5 text-accent" strokeWidth={1.5} />
          <span className="font-serif font-bold text-base-content tracking-tight">SnapVault</span>
        </div>
        <button
          className="btn btn-ghost btn-sm btn-square"
          onClick={() => setIsDark(!isDark)}
          aria-label="Toggle theme"
        >
          {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
        </button>
      </div>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div
          className="lg:hidden fixed inset-0 bg-neutral/50 z-50 backdrop-blur-sm"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`
          fixed top-0 left-0 z-50 h-full w-60 bg-base-200 border-r border-base-300
          flex flex-col transition-transform duration-300 ease-in-out
          lg:translate-x-0 lg:static lg:z-auto
          ${mobileOpen ? "translate-x-0" : "-translate-x-full"}
        `}
      >
        {/* Logo */}
        <div className="flex items-center justify-between px-5 py-5 border-b border-base-300">
          <div className="flex items-center gap-2.5">
            <Camera className="h-5 w-5 text-accent" strokeWidth={1.5} />
            <span className="font-serif font-bold text-lg text-base-content">SnapVault</span>
          </div>
          <button
            className="btn btn-ghost btn-sm btn-square lg:hidden"
            onClick={() => setMobileOpen(false)}
            aria-label="Close menu"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4 px-3">
          <p className="text-[10px] uppercase tracking-[0.15em] text-base-content/40 font-semibold px-3 mb-2">
            Library
          </p>
          <ul className="menu gap-0.5 p-0">
            {navItems.slice(0, 4).map((item) => (
              <li key={item.section}>
                <button
                  onClick={() => handleNav(item.section)}
                  className={`
                    flex items-center gap-3 px-3 py-2 rounded-md text-sm
                    transition-colors w-full text-left
                    ${
                      activeSection === item.section
                        ? "bg-accent/15 text-accent font-semibold border-l-2 border-accent -ml-px"
                        : "text-base-content/60 hover:bg-base-300/60 hover:text-base-content"
                    }
                  `}
                >
                  <item.icon className="h-4 w-4 shrink-0" strokeWidth={1.5} />
                  {item.label}
                </button>
              </li>
            ))}
          </ul>

          <div className="border-t border-base-300 my-3" />

          <p className="text-[10px] uppercase tracking-[0.15em] text-base-content/40 font-semibold px-3 mb-2">
            Manage
          </p>
          <ul className="menu gap-0.5 p-0">
            {navItems.slice(4).map((item) => (
              <li key={item.section}>
                <button
                  onClick={() => handleNav(item.section)}
                  className={`
                    flex items-center gap-3 px-3 py-2 rounded-md text-sm
                    transition-colors w-full text-left
                    ${
                      activeSection === item.section
                        ? "bg-accent/15 text-accent font-semibold border-l-2 border-accent -ml-px"
                        : "text-base-content/60 hover:bg-base-300/60 hover:text-base-content"
                    }
                  `}
                >
                  <item.icon className="h-4 w-4 shrink-0" strokeWidth={1.5} />
                  {item.label}
                </button>
              </li>
            ))}
          </ul>
        </nav>

        {/* Bottom */}
        <div className="border-t border-base-300 p-4 flex flex-col gap-3">
          {/* Theme toggle */}
          <label className="flex items-center justify-between cursor-pointer">
            <span className="text-xs text-base-content/50">Dark Mode</span>
            <input
              type="checkbox"
              className="toggle toggle-sm toggle-accent"
              checked={isDark}
              onChange={() => setIsDark(!isDark)}
            />
          </label>

          {/* User */}
          <div className="flex items-center gap-3">
            <div className="avatar placeholder">
              <div className="bg-accent/20 text-accent w-8 rounded-full">
                <span className="text-xs font-bold">JD</span>
              </div>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-base-content truncate">Jane Doe</p>
              <p className="text-[11px] text-base-content/40 truncate">jane@example.com</p>
            </div>
            <button className="btn btn-ghost btn-xs btn-square text-base-content/40 hover:text-base-content" aria-label="Settings">
              <Settings className="h-3.5 w-3.5" strokeWidth={1.5} />
            </button>
          </div>
        </div>
      </aside>
    </>
  )
}
