import { Heart } from "lucide-react"
import Image from "next/image"

const favPhotos = [
  { src: "/images/photo-1.jpg", title: "Golden Hills" },
  { src: "/images/photo-3.jpg", title: "City Dusk" },
  { src: "/images/photo-6.jpg", title: "Butterfly" },
]

export function FavoritesSection() {
  return (
    <section>
      <div className="mb-8">
        <h2 className="text-3xl font-serif font-bold text-base-content text-balance">Favorites</h2>
        <p className="text-sm text-base-content/40 mt-1">3 photos</p>
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {favPhotos.map((photo) => (
          <div key={photo.title} className="group cursor-pointer">
            <figure className="relative aspect-[4/3] overflow-hidden rounded-md bg-base-300">
              <Image src={photo.src} alt={photo.title} fill className="object-cover" />
              <button className="absolute top-2.5 left-2.5 btn btn-xs btn-circle bg-accent text-accent-content border-none" aria-label="Unfavorite">
                <Heart className="h-3 w-3 fill-current" strokeWidth={1.5} />
              </button>
            </figure>
            <div className="pt-2.5 px-0.5">
              <h3 className="text-sm font-medium text-base-content">{photo.title}</h3>
            </div>
          </div>
        ))}
      </div>
    </section>
  )
}
